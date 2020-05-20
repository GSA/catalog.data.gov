import json
import requests
from remote_ckan.logs import get_logger

logger = get_logger(__name__)


class RemoteCKAN:
    def __init__(self, url, user_agent='Remote CKAN 1.0'):
        self.url = url
        self.user_agent = user_agent
        self.errors = []
        logger.debug(f'New remote CKAN {url}')
    
    def set_destination(self, ckan_url, ckan_api_key):
        self.destination_url = ckan_url
        self.api_key = ckan_api_key

    def list_harvest_sources(self, source_type=None, start=0, page_size=100):
        """ Generator for a list of harvest sources at a CKAN instance
            Params:
                source_type (str): datajson | csw | None=ALL
                limit (int): max number of harvest sources to read 
        """  
        logger.debug(f'List harvest sources {start}-{page_size}')
        package_search_url = f'{self.url}/api/3/action/package_search'
        # TODO use harvest_source_list for harvester ext
        
        if source_type is None or source_type == 'ALL':
            q = f'(type:harvest)'
        else:
            q = f'(type:harvest source_type:{source_type})'

        params = {'start': start, 'rows': page_size, 'q': q}
        headers = {'User-Agent': self.user_agent}

        logger.debug(f'request {package_search_url} {params}')
        # response = requests.post(package_search_url, json=params, headers=headers)
        response = requests.get(package_search_url, params=params, headers=headers)
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
            title = hs['title']
            source_type = hs['source_type']  # datajosn, waf, etc
            state = hs['state']
            name = hs['name']
            
            logger.info(f'  [{source_type}] Harvest source: {title} [{state}]')
            if state == 'active':
                # We don't get full harvest soure info here. We need a custom call
                harvest_show_url = f'{self.url}/api/3/action/harvest_source_show'
                params = {'id': name}
                logger.info(f'Get harvest source data {harvest_show_url} {params}')
                response = requests.get(harvest_show_url, params=params, headers=headers)
                if response.status_code >= 400:
                    error = f'Error [{response.status_code}] trying to get full harvest source info about "{title}" ({name})'
                    logger.error(error)
                    self.errors.append(error)
                    # yield incomplete version
                    yield hs
                else:
                    full_hs = response.json()
                    yield full_hs['result']

        # if the page is not full, is the last one
        if count + 1 < page_size:
            return

        # get next page   
        yield from self.list_harvest_sources(source_type=source_type, start=start + page_size, page_size=page_size)
    
    def get_request_headers(self, include_api_key=True):
        headers = {'User-Agent': f'{self.user_agent}'}
        if include_api_key:
            headers['X-CKAN-API-Key'] = self.api_key
        return headers

    def create_harvest_source(self, data):
        """ create a harvest source (is just a CKAN dataset/package)
            Ensure to create the organization first.
            params:
                data (dict): Harvest source dict

            returns:
                created (boolean):
                status_code (int): request status code
                error (str): None or error
            """
    
        created, status, error = self.create_organization(data=data['organization'])
        if not created:
            return False, status, f'Unable to create organization: {error}'

        logger.info(data)
        config = data.get('config', {})
        if type(config) == str:
            config = json.loads(config)

        # we can also have config in extras
        # we don't get extras 
        extras = data.get('extras', {})
        for extra in extras:
            if extra['key'] == 'config':
                logger.info(f'Config found in extras: {extra}')
                value = json.loads(extra['value'])
                config.update(value)

        ckan_package = {
            'name': data['name'],
            'owner_org': data['organization']['name'],
            'title': data['title'],
            'url': data['url'],
            'notes': data['notes'],
            'source_type': data['source_type'],
            'frequency': data['frequency'],
            'config': json.dumps(config, indent=4)
        } 

        package_create_url = f'{self.destination_url}/api/3/action/harvest_source_create'
        headers = self.get_request_headers(include_api_key=True)

        logger.info('Creating havervest source {} \n\t{} \n\t{}'.format(ckan_package['title'], data['url'], config))

        try:
            req = requests.post(package_create_url, data=ckan_package, headers=headers)
        except Exception as e:
            error = 'ERROR creating harvest source: {} [{}]'.format(e, ckan_package)
            return False, 0, error

        content = req.content
        try:
            json_content = json.loads(content)
        except Exception as e:
            error = 'ERROR parsing JSON data: {} [{}]'.format(content, e)
            logger.error(error)
            return False, 0, error
        
        if req.status_code >= 400:
            if 'That URL is already in use' in str(content):
                return False, req.status_code, 'Already exists'
            error = ('ERROR creating harvest source: {}'
                     '\n\t Status code: {}'
                     '\n\t content:{}'.format(ckan_package, req.status_code, req.content))
            self.errors.append(error)
            logger.error(error)
            return False, req.status_code, error

        if not json_content['success']:
            error = 'API response failed: {}'.format(json_content.get('error', None))
            logger.error(error)
            self.errors.append(error)
            return False, req.status_code, error

        logger.info('Harvest source created OK {}'.format(ckan_package['title']))
        return True, req.status_code, None
    
    def create_organization(self, data):
        """ Creates a new organization in CKAN destination 
            Params:
                data (dics): Required fields to create
        """

        package_create_url = f'{self.destination_url}/api/3/action/organization_create'
        headers = self.get_request_headers(include_api_key=True)

        logger.info('Creating organization {}'.format(data['title']))

        organization = {
            'name': data['name'],
            'title': data['title'],
            'description': data['description'],
            'id': data['id'],
            'image_url': data['image_url']
        }

        # TODO get the organization_type GSA field

        try:
            req = requests.post(package_create_url, data=organization, headers=headers)
        except Exception as e:
            error = 'ERROR creating organization: {} [{}]'.format(e, organization)
            self.errors.append(error)
            return False, 0, error

        content = req.content
        try:
            json_content = json.loads(content)
        except Exception as e:
            error = 'ERROR parsing JSON data: {} [{}]'.format(content, e)
            logger.error(error)
            return False, 0, error
        
        if req.status_code >= 400:
            if 'already in use' in str(content):
                return False, req.status_code, 'Already exists'
            error = ('ERROR creating organization: {}'
                     '\n\t Status code: {}'
                     '\n\t content:{}'.format(organization, req.status_code, req.content))
            logger.error(error)
            return False, req.status_code, error

        if not json_content['success']:
            error = 'API response failed: {}'.format(json_content.get('error', None))
            logger.error(error)
            return False, req.status_code, error

        logger.info('Organization created OK {}'.format(organization['title']))
        return True, req.status_code, None