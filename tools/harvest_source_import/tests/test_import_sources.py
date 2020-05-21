import pytest
from remote_ckan.lib import RemoteCKAN


@pytest.mark.vcr()
def test_load_from_url():

    ckan = RemoteCKAN(url='https://catalog.data.gov')
    ckan.set_destination(ckan_url='http://ckan:5000',
                         ckan_api_key='8364b33a-832f-45ab-8d2d-71dba1b8d9796')

    harvest_sources = []
    ok = 0
    failed = 0
    already_exists = 0

    print('Getting harvest sources ...')
    for hs in ckan.list_harvest_sources(source_type='datajson'):

        harvest_sources.append(hs)
        print('Getting {}'.format(hs['name']))
        # save to destination CKAN    
        created, status_code, error = ckan.create_harvest_source(data=hs)
        if created: 
            ok += 1
        elif error == 'Already exists':
            already_exists += 1
        else:
            failed += 1
        
        # limit
        if ok + already_exists + failed == 10:
            break

    print('Finished: {} harvest sources. {} Added, {} already exists, {} failed'.format(len(harvest_sources), ok, already_exists, failed))
    
    assert ok == 9
    assert failed == 1
    assert already_exists == 0
