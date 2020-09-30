""" test the list of harvest sources
 - Add this to VCR cassette: python -m pytest -s --vcr-record=all tests/test_list_sources.py
"""

import pytest
import vcr
from time import sleep
from remote_ckan.lib import RemoteCKAN
import urllib.parse as urlparse

@pytest.mark.vcr()
def test_list_ckan_sources():
    """ Test the list of sources """

    ckan = RemoteCKAN(url='https://catalog.data.gov')
    total = 0
    expected_names = ['doi-open-data', 'test-2016']

    results = {}
    for hs in ckan.list_harvest_sources(source_type='ckan'):
        total += 1
        assert hs['source_type'] == 'ckan'
        assert hs['name'] in expected_names
        results[hs['name']] = hs

    assert total == 2
    assert results['doi-open-data']['url'] == 'https://data.doi.gov'
    assert results['doi-open-data']['status']['job_count'] == 1


def test_requests_sent_for_ckan_sources():
    cass = vcr.cassette.Cassette.load(path='tests/cassettes/test_list_ckan_sources.yaml')
    search_request = cass.requests[0]
    assert'/api/3/action/package_search' in search_request.uri
    parsed = urlparse.urlparse(search_request.uri)
    params = urlparse.parse_qs(parsed.query)
    assert params['q'] == ['(type:harvest source_type:ckan)']
    assert params['fq'] == ['+dataset_type:harvest']
    assert search_request.headers['User-Agent'] == 'Remote CKAN 1.0'
    assert search_request.method == 'GET'


@pytest.mark.vcr()
def test_list_datajson_sources():
    """ Test the list of sources """

    ckan = RemoteCKAN(url='https://catalog.data.gov')
    total = 0
    
    results = {}
    for hs in ckan.list_harvest_sources(source_type='datajson'):
        total += 1
        # some sources fails in production (didn't return the full source)
        assert hs.get('source_type', 'datajson') == 'datajson'
        results[hs['name']] = hs
        # just for the real requests
        # sleep(2)
        
    assert total == 152
    assert results['doj-json']['url'] == 'http://www.justice.gov/data.json'
    assert results['doj-json']['frequency'] == 'DAILY'
    assert results['doj-json']['status']['job_count'] == 235
    assert results['doj-json']['status']['total_datasets'] == 1236


def test_requests_sent_for_datajson_soruces():
    cass = vcr.cassette.Cassette.load(path='tests/cassettes/test_list_datajson_sources.yaml')
    search_request = cass.requests[0]
    assert'/api/3/action/package_search' in search_request.uri
    parsed = urlparse.urlparse(search_request.uri)
    params = urlparse.parse_qs(parsed.query)
    assert params['q'] == ['(type:harvest source_type:datajson)']
    assert params['fq'] == ['+dataset_type:harvest']
    assert search_request.headers['User-Agent'] == 'Remote CKAN 1.0'
    assert search_request.method == 'GET'


@pytest.mark.vcr()
def test_list_all_sources():
    """ Test the list of sources """

    ckan = RemoteCKAN(url='https://catalog.data.gov')
    total = 0
    
    results = {}
    for hs in ckan.list_harvest_sources(skip_full_source_info=True):
        total += 1
        results[hs['name']] = hs
        
    assert 'doi-open-data' in results
    assert total == 1083
    