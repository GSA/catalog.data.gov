import pytest
from remote_ckan.lib import RemoteCKAN


@pytest.mark.vcr()
def test_load_from_url():
    """ Test with some previous harvester already saved
        Use a pytest cassette so real requests are not required. 
        We import 3 harvest sources (so they already exists) 
        and then run this test with 6 sources. """

    ckan = RemoteCKAN(url='https://catalog.data.gov')
    ckan.set_destination(ckan_url='http://ckan:5000',
                         ckan_api_key='7564fcf7-1e79-4e03-a052-f94979051770')

    print('Getting harvest sources ...')
    for hs in ckan.list_harvest_sources(source_type='datajson', limit=9):

        ckan.create_harvest_source(data=hs)
        assert 'created' in ckan.harvest_sources[hs['name']].keys()
        assert 'updated' in ckan.harvest_sources[hs['name']].keys()
        assert 'error' in ckan.harvest_sources[hs['name']].keys()

    created = len([k for k, v in ckan.harvest_sources.items() if v['created'] ])
    updated = len([k for k, v in ckan.harvest_sources.items() if v['updated'] ])
    errors = len([k for k, v in ckan.harvest_sources.items() if v['error'] ])
    total = created + updated + errors

    print('Finished: {} harvest sources. {} Added, {} already exists, {} failed'.format(total, created, updated, errors))

    assert total == len(ckan.harvest_sources)
    assert created == 3
    assert updated == 6
    assert errors == 0

