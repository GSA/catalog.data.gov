""" test the list of harvest sources
 - Add this to VCR cassette: python -m pytest -s --vcr-record=all tests/test_list_sources.py
"""

import pytest
import vcr
from remote_ckan.lib import RemoteCKAN


@pytest.mark.vcr()
def test_list_ckan_sources():
    """ Test the list of sources """

    ckan = RemoteCKAN(url='https://catalog-next.sandbox.datagov.us')
    total = 0
    expected_names = ['datos-argentina', 'doi-open-data' ,'sandbox-catalog-classic', 'test-2016']

    results = {}
    for hs in ckan.list_harvest_sources(source_type='ckan'):
        total += 1
        assert hs['source_type'] == 'ckan'
        assert hs['name'] in expected_names
        results[hs['name']] = hs

    assert total == 4
    assert results['doi-open-data']['url'] == 'https://data.doi.gov'
    assert results['doi-open-data']['status']['job_count'] == 2


@pytest.mark.vcr()
def test_list_datajson_sources():
    """ Test the list of sources """

    ckan = RemoteCKAN(url='https://catalog-next.sandbox.datagov.us')
    total = 0
    
    results = {}
    for hs in ckan.list_harvest_sources(source_type='datajson'):
        total += 1
        assert hs['source_type'] == 'datajson'
        results[hs['name']] = hs
        
    assert total == 156
    assert results['doj-json']['url'] == 'http://www.justice.gov/data.json'
    assert results['doj-json']['frequency'] == 'DAILY'
    assert results['doj-json']['status']['job_count'] == 44
    assert results['doj-json']['status']['total_datasets'] == 1243
