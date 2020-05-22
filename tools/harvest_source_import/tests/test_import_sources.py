import pytest
from remote_ckan.lib import RemoteCKAN


@pytest.mark.vcr()
def test_load_from_url():
    """ Test with some previous harvester already saved
        Use a pytest cassette so real requests are not required. """

    ckan = RemoteCKAN(url='https://catalog.data.gov')
    ckan.set_destination(ckan_url='http://ckan:5000',
                         ckan_api_key='2feae71c-0aed-453f-85f4-1bb7bfdb6e63')

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
        if ok + already_exists + failed == 20:
            break

    print('Finished: {} harvest sources. {} Added, {} already exists, {} failed'.format(len(harvest_sources), ok, already_exists, failed))
    
    assert ok == 10
    assert failed == 0
    assert already_exists == 10
