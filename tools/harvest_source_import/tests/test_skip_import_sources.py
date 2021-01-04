import pytest
from import_harvest_sources import import_sources


@pytest.mark.vcr()
def test_skip():
    
    res = import_sources(
        origin_url='https://catalog.data.gov',
        source_type='ALL',
        user_agent='CKAN-harvest-source-importer 1.0 (https://github.com/GSA/catalog.data.gov/tree/master/tools/harvest_source_import)',
        destination_url='http://ckan:5000',
        limit=0, offset=0, wait_for_show=0, wait_for_create=0,
        names='fdic-data-json,fcc,fhfa-json,nc-onemap-csw,cfpb-json,2018-addr,wv-gis-technical-center',
        destination_api_key='4f0c7f07-afdc-401d-bed0-dc51138c3e23',
        skip_sources_file='skip/skip-sources-sample.json',
        skip_orgs_file='skip/skip-orgs-sample.json'
    )

    assert res['fhfa-json']['skipped'] == 'source'
    assert res['nc-onemap-csw']['skipped'] == 'organization'
    

