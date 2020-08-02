import json
import os

import requests

from remote_ckan.logs import get_logger

logger = get_logger(__name__)


class RemoteCKAN:
    def __init__(self, url,
                 user_agent='Remote CKAN 1.0',
                 temp_data='checks',
                 requests_timeout=60):
        self.url = url
        self.user_agent = user_agent
        self.errors = []
        self.harvest_sources = {}
        self.organizations = {}
        self.groups = {}
        logger.debug(f'New remote CKAN {url}')
        # save results temp data into a new folder
        self.temp_data = temp_data
        if not os.path.isdir(self.temp_data):
            os.mkdir(self.temp_data)

        self.requests_timeout = requests_timeout

    def set_destination(self, ckan_url, ckan_api_key):
        self.destination_url = ckan_url
        self.api_key = ckan_api_key

    def list_harvest_sources(self, source_type=None, start=0, page_size=100, limit=0):
        """ Generator for a list of harvest sources at a CKAN instance
            Params:
                source_type (str): datajson | csw | None=ALL
                limit (int): max number of harvest sources to read
        """

        logger.debug(f'List harvest sources {start}-{page_size}')

        package_search_url = f'{self.url}/api/3/action/package_search'
        # TODO use harvest_source_list for harvester ext

        if source_type is None or source_type == 'ALL':
            q = '(type:harvest)'
        else:
            q = f'(type:harvest source_type:{source_type})'

        params = {'start': start, 'rows': page_size, 'q': q, 'fq': '+dataset_type:harvest'}
        headers = self.get_request_headers(include_api_key=False)

        logger.debug(f'request {package_search_url} {params}')
        response = requests.get(package_search_url, params=params, headers=headers, timeout=self.requests_timeout)
        if response.status_code >= 400:
            error = f'ERROR getting harvest sources: {response.status_code} {response.text}'
            self.errors.append(error)
            logger.error(error)
            raise ValueError(error)

        data = response.json()

        if not data['success']:
            error = 'ERROR searching harvest sources {}'.format(data['error'])
            logger.error(error)
            self.errors.append(error)
            raise ValueError(error)

        total = data['result']['count']
        count = len(data['result']['results'])
        if count == 0:
            return

        harvest_sources = data['result']['results']
        logger.info(f'{count} ({total}) harvest sources found')

        for hs in harvest_sources:
            total_sources = len(self.harvest_sources)
            if limit > 0 and total_sources >= limit:
                return
            title = hs['title']
            source_type = hs['source_type']  # datajosn, waf, etc
            state = hs['state']
            name = hs['name']
            self.harvest_sources[name] = hs

            logger.info(f'  [{source_type}] Harvest source: {title} [{state}]')
            if state == 'active':
                # We don't get full harvest soure info here. We need a custom call
                source = self.get_full_harvest_source(hs)
                if source is None:
                    source = {'name': hs['name'], 'created': False, 'updated': False, 'error': True}
                yield source

        # if the page is not full, it is the last one
        if count + 1 < page_size:
            return

        # get next page
        yield from self.list_harvest_sources(source_type=source_type, start=start + page_size, page_size=page_size, limit=limit)

    def get_full_harvest_source(self, hs, url=None):
        """ get full info (including job status) for a Harvest Source """
        if url is None:
            url = self.url
        harvest_show_url = f'{url}/api/3/action/harvest_source_show'

        if 'id' in hs.keys():
            params = {'id': hs['id']}
        else:
            params = {'name_or_id': hs['name']}

        headers = self.get_request_headers(include_api_key=False)

        error = None
        logger.info(f'Get harvest source data {harvest_show_url} {params}')
        try:
            response = requests.get(harvest_show_url, params=params, headers=headers, timeout=self.requests_timeout)
        except Exception as e:
            error = f'Request harvest source Error: {e}'
        else:
            if response.status_code >= 500:
                error = f'Error [{response.status_code}] getting harvest source info: {harvest_show_url}\n\t{params}'
            elif response.status_code >= 400:
                error = f'Error [{response.status_code}] getting harvest source info: "{response.content}"'

        if error is not None:
            logger.error(error)
            self.errors.append(error)
            name = hs['name']
            source = {'name': name, 'created': False, 'updated': False, 'error': True}
            self.harvest_sources[name] = source
            return None

        full_hs = response.json()
        self.harvest_sources[hs['name']] = full_hs['result']
        self.save_temp_json('harvest-source', full_hs['result']['name'], full_hs['result'])
        return full_hs['result']

    def get_full_organization(self, org, url=None):
        """ get full info (including job status) for a Harvest Source """

        if url is None:
            url = self.url

        organization_show_url = f'{url}/api/3/action/organization_show'

        org_id = org.get('name', org.get('id', None))
        if org_id is None:
            return None

        params = {'id': org_id}
        headers = self.get_request_headers(include_api_key=False)

        logger.info(f'Get organization data {organization_show_url} {params}')

        # not sure why require this
        headers['Content-Type'] = 'application/x-www-form-urlencoded'
        params = json.dumps(params)

        error = None

        try:
            response = requests.post(organization_show_url, data=params, headers=headers, timeout=self.requests_timeout)
        except Exception as e:
            error = f'Request organization Error: {e}'
        else:
            if response.status_code >= 400:
                error = f'Error [{response.status_code}] getting organization info:\n {params} \n{response.headers}\n {response.content}'
                logger.error(error)
                self.errors.append(error)
            else:
                response = response.json()
                org = response['result']

        if error is not None:
            logger.error(error)
            self.errors.append(error)

            return None

        self.save_temp_json('organization', org.get('name', org.get('id', 'unnamed')), org)
        self.organizations[org['name']] = org
        return org

    def get_request_headers(self, include_api_key=True):
        headers = {'User-Agent': self.user_agent}
        if include_api_key:
            headers['X-CKAN-API-Key'] = self.api_key
        return headers

    def create_harvest_source(self, data):
        """ create a harvest source (is just a CKAN dataset/package)
            This will create the organization if it does not already exist.
            params:
                data (dict): Harvest source dict

            returns:
                created (boolean):
                status_code (int): request status code
                error (str): None or error
            """

        org = data.get('organization', None)
        if org is None:
            self.harvest_sources[data['name']].update({'created': False, 'updated': False, 'error': True})
            return False, 0, f'Missing organization at \n\t{data}'

        created, status, error = self.create_organization(data=org)
        if not created:
            self.harvest_sources[data['name']].update({'created': False, 'updated': False, 'error': True})
            return False, status, f'Unable to create organization: {error}'

        config = data.get('config', {})
        if type(config) == str:
            config = json.loads(config)
        default_groups = config.get('default_groups', [])
        if type(default_groups) == str:
            default_groups = [default_groups]
        for group in default_groups:
            created, status, error = self.create_group(group_name=group)
            if not created:
                self.harvest_sources[data['name']].update({'created': False, 'updated': False, 'error': True})
                return False, status, f'Unable to create group: {error}'

        ckan_package = self.get_package_from_data(data)

        package_create_url = f'{self.destination_url}/api/3/action/harvest_source_create'
        logger.info('Creating harvest source {} \n\t{} \n\t{}'.format(ckan_package['title'], data['url'], ckan_package['config']))

        created, status, error = self.request_ckan(url=package_create_url, method='POST', data=ckan_package)

        if error == 'Already exists':
            # get the ID of the Source (use destination URL)
            del data['id']
            local_hs = self.get_full_harvest_source(hs=data, url=self.destination_url)
            data['id'] = local_hs['id']
            return self.update_harvest_source(data=data)
        else:
            name = ckan_package['name']
            self.harvest_sources[name].update({'created': created, 'updated': False, 'error': error is not None})
            return created, status, error

    def update_harvest_source(self, data):
        """ update a harvest source if already exists
            params:
                data (dict): Harvest source dict

            returns:
                created (boolean):
                status_code (int): request status code
                error (str): None or error
            """

        ckan_package = self.get_package_from_data(data)

        package_update_url = f'{self.destination_url}/api/3/action/harvest_source_update'
        logger.info(' ** Updating harvest source {} \n\t{} \n\t{}'.format(ckan_package['title'], data['url'], ckan_package['config']))

        updated, status, error = self.request_ckan(url=package_update_url, method='POST', data=ckan_package)
        name = ckan_package['name']
        self.harvest_sources[name].update({'created': False, 'updated': updated, 'error': error is not None})

        return updated, status, error

    def get_full_group(self, group_name, url=None):
        """ get full info (including job status) for a Harvest Source """
        if url is None:
            url = self.url

        group_show_url = f'{url}/api/3/action/group_show'

        params = {'id': group_name}
        headers = self.get_request_headers(include_api_key=False)

        logger.info(f'Get group data {group_show_url} {params}')

        # not sure why require this
        headers['Content-Type'] = 'application/x-www-form-urlencoded'
        params = json.dumps(params)

        error = None

        try:
            response = requests.post(group_show_url, data=params, headers=headers, timeout=self.requests_timeout)
        except Exception as e:
            error = f'Request group Error: {e}'
        else:
            if response.status_code >= 400:
                error = f'Error [{response.status_code}] getting group info:\n {params} \n{response.headers}\n {response.content}'
                logger.error(error)
                self.errors.append(error)
            else:
                response = response.json()
                group = response['result']

        if error is not None:
            logger.error(error)
            self.errors.append(error)

            return None

        self.save_temp_json('group', group.get('name', group.get('id', 'unnamed')), group)
        self.groups[group['name']] = group
        return group

    def create_group(self, group_name):
        """ Creates a new group in CKAN destination
            Params:
                data (dics): Required fields to create
        """
        full_group = self.get_full_group(group_name=group_name)

        # remove packages from data because they are not harvested yet
        full_group.pop('packages', None)
        full_group.pop('id', None)

        logger.info('Creating group {}'.format(full_group['name']))

        group_create_url = f'{self.destination_url}/api/3/action/group_create'

        # check if group exists at destination url

        group_at_destination = self.get_full_group(group_name=group_name, url=self.destination_url)

        if group_at_destination is not None:
            full_group['id'] = group_at_destination['id']
            created, status, error = self.update_group(data=full_group)
        else:
            created, status, error = self.request_ckan(method='POST', url=group_create_url, data=full_group)

        return created, status, error

    def update_group(self, data):
        """ update an existing group """

        group_update_url = f'{self.destination_url}/api/3/action/group_update'
        return self.request_ckan(method='POST', url=group_update_url, data=data)

    def create_organization(self, data):
        """ Creates a new organization in CKAN destination
            Params:
                data (dics): Required fields to create
        """

        # get more info about org, we miss organization extras
        # We need the organization_type in some cases
        full_org = self.get_full_organization(org=data)
        extras = data.get('extras', [])
        for extra in full_org.get('extras', []):
            if extra.get('state', 'active') == 'active':
                extras.append({'key': extra['key'], 'value': extra['value']})
                logger.info('New extra found at org {}={}'.format(extra['key'], extra['value']))

        org_create_url = f'{self.destination_url}/api/3/action/organization_create'

        organization = {
            'name': data['name'],
            'title': data['title'],
            'description': data['description'],
            'image_url': data['image_url'],
            'extras': extras
        }
        logger.info('Creating organization {}'.format(data['name']))

        organization_at_destination = self.get_full_organization(org=data, url=self.destination_url)

        if organization_at_destination is not None:
            organization['id'] = organization_at_destination['id']
            created, status, error = self.update_organization(data=organization)
        else:
            created, status, error = self.request_ckan(method='POST', url=org_create_url, data=organization)

        return created, status, error

    def update_organization(self, data):
        """ update an existing organization """

        org_update_url = f'{self.destination_url}/api/3/action/organization_update'
        return self.request_ckan(method='POST', url=org_update_url, data=data)

    def get_config(self, data):
        """ get config and extras from full data package and return a final str config """
        config = data.get('config', {})
        if type(config) == str:
            config = json.loads(config)

        # We may have config defined as extras
        extras = data.get('extras', [])

        for extra in extras:
            if extra['key'] == 'config':
                logger.info(f'Config found in extras: {extra}')
                value = json.loads(extra['value'])
                config.update(value)
                extras.remove(extra)

        return json.dumps(config)

    def get_collection_metadata_url(self, config):
        """ get collection_metadata_url from config """
        if type(config) == str:
            config = json.loads(config)

        collection_metadata_url = config.get('collection_metadata_url', None)

        return collection_metadata_url

    def request_ckan(self, method, url, data):
        """ request CKAN and get results """

        headers = self.get_request_headers(include_api_key=True)
        # do not modify original data
        data2 = data.copy()

        try:
            if method == 'POST':
                req = requests.post(url, json=data2, headers=headers, timeout=self.requests_timeout)
            elif method == 'GET':
                req = requests.get(url, params=data2, headers=headers, timeout=self.requests_timeout)
            else:
                raise ValueError(f'Invalid method {method}')

        except Exception as e:
            error = 'ERROR at {} {}: {}'.format(url, data2, e)
            return False, 0, error

        content = req.content
        try:
            json_content = json.loads(content)
        except Exception as e:
            error = 'ERROR parsing JSON: {} {}: {}'.format(url, content, e)
            logger.error(error)
            self.errors.append(error)
            return False, 0, error

        if req.status_code >= 400:
            if 'already exists' in str(content) or 'already in use' in str(content):
                return False, req.status_code, 'Already exists'
            error = ('ERROR status: {}'
                     '\n\t content:{}'
                     '\n\t sent: {}'.format(req.status_code, req.content, data2))
            self.errors.append(error)
            logger.error(error)
            return False, req.status_code, error

        if not json_content['success']:
            error = 'API response failed: {}'.format(json_content.get('error', None))
            logger.error(error)
            self.errors.append(error)
            return False, req.status_code, error

        logger.info('Request OK {}'.format(url))
        return True, req.status_code, None

    def get_package_from_data(self, data):
        """ get full data package and return a final CKAN package """

        config = self.get_config(data)
        extras = data.get('extras', [])

        ret = {
            'name': data['name'],
            'owner_org': data['organization']['name'],
            'title': data['title'],
            'url': data['url'],
            'notes': data['notes'],
            'source_type': data['source_type'],
            'frequency': data['frequency'],
            'config': config,
            'extras': extras
        }

        collection_metadata_url = self.get_collection_metadata_url(config)

        if collection_metadata_url is not None:
            ret['collection_metadata_url'] = collection_metadata_url

        if data.get('database', None) is not None:
            ret['database'] = data['database']

        if data.get('port', None) is not None:
            ret['port'] = data['port']

        if data.get('extra_search_criteria', None) is not None:
            ret['extra_search_criteria'] = data['extra_search_criteria']

        if data.get('id', None) is not None:
            ret['id'] = data['id']

        return ret

    def save_temp_json(self, data_type, data_name, data):
        filename = '{}-{}.json'.format(data_type, data_name)
        path = os.path.join(self.temp_data, filename)
        f = open(path, 'w')
        f.write(json.dumps(data, indent=4))
        f.close()
        logger.info('{} {} saved at /{}'.format(data_type, data_name, self.temp_data))
