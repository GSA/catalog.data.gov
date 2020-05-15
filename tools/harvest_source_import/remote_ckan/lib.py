import requests
from remote_ckan.logs import get_logger

logger = get_logger(__name__)


class RemoteCKAN:
    def __init__(self, url, user_agent='Remote CKAN 1.0'):
        self.url = url
        self.user_agent = user_agent
        logger.info(f'New remote CKAN {url}')

    def list_harvest_sources(self, source_type=None, start=0, page_size=10):
        """ Generator for a list of harvest sources at a CKAN instance
            Params:
                source_type (str): datajson | csw | None=ALL
                limit (int): max number of harvest sources to read 
        """  
        logger.info(f'List harvest sources {start}-{page_size}')
        package_search_url = f'{self.url}/api/3/action/package_search'
        
        if source_type is None or source_type == 'ALL':
            q = f'(type:harvest)'
        else:
            q = f'(type:harvest source_type:{source_type})'

        params = {'start': start, 'rows': page_size, 'q': q}
        headers = {'User-Agent': self.user_agent}

        logger.info(f'request {package_search_url} {params}')
        # response = requests.post(package_search_url, json=params, headers=headers)
        response = requests.get(package_search_url, params=params, headers=headers)
        if response.status_code >= 400:
            error = f' - ERROR Response {response.status_code} {response.text}'
            logger.error(error)
            raise ValueError(error)

        data = response.json()

        if not data['success']:
            error = 'ERROR searching harvest sources {}'.format(data['error'])
            print(error)
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
            logger.info(f'  [{source_type}] Harvest source: {title}')
            yield hs

        # if the page is not full, is the last one
        if count < page_size:
            return

        # get next page   
        yield from self.list_harvest_sources(source_type=source_type, start=start + page_size, page_size=page_size)