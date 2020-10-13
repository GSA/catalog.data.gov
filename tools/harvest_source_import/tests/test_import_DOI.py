import json
import pytest
from remote_ckan.lib import RemoteCKAN


@pytest.mark.vcr()
def test_load_from_name():
    """ Test source using force_all config. """

    ckan = RemoteCKAN(url='https://catalog.data.gov')
    ckan.set_destination(ckan_url='http://ckan:5000',
                         ckan_api_key='0602d7ed-1517-40a0-a92f-049d724962df')

    print('Getting harvest source ...')
    
    name = 'doi-open-data'
    full_hs = ckan.get_full_harvest_source(hs={'name': name})
    ckan.create_harvest_source(data=full_hs)
    assert 'created' in ckan.harvest_sources[name].keys()
    assert ckan.harvest_sources[name]['created']
    assert 'updated' in ckan.harvest_sources[name].keys()
    assert not ckan.harvest_sources[name]['updated']
    assert 'error' in ckan.harvest_sources[name].keys()
    assert not ckan.harvest_sources[name]['error']

    print(ckan.harvest_sources[name])
    
    # check the force_all config
    cfg = ckan.harvest_sources[name]['ckan_package']['config']
    cfg_data = json.loads(cfg)
    assert type(cfg_data['force_all']) == bool
    assert cfg_data['force_all']
