import unittest
from unittest import mock

import requests

from remote_ckan.lib import RemoteCKAN

mock_url = 'mock://ckan'

def mock_response(status_code=200, data=None):
    m = mock.Mock()
    m.status_code = status_code
    m.json = mock.Mock(return_value=data)
    return m

def api_call(url, params):
    """Helper for making assertions against requests mocks."""
    return mock.call('%s%s' % (mock_url, url), headers=mock.ANY, timeout=mock.ANY, params=params)



@mock.patch('requests.get')
def test_list_harvest_sources_with_pagination(mock_requests):
    """Test list_harvest_sources pagination with multiple source types."""
    ckan = RemoteCKAN(mock_url)
    expected_harvest_source_1 = mock.sentinel.harvest_source_1
    expected_harvest_source_2 = mock.sentinel.harvest_source_2

    # Grab the generator
    harvest_sources = ckan.list_harvest_sources(start=0, page_size=1)

    # First page
    ckan.get_full_harvest_source = mock.Mock(return_value=expected_harvest_source_1) # stub
    mock_requests.return_value = mock_response(data={
        'success': True,
        'result': {
            'count': 2,
            'results': [
                {
                    'title': 'dataset 1',
                    'name': 'dataset-1',
                    'state': 'active',
                    'type': 'harest',
                    'source_type': 'waf',
                },
            ],
        },
    })
    assert next(harvest_sources) == expected_harvest_source_1
    assert mock_requests.mock_calls == [
        api_call('/api/3/action/package_search', params=dict(start=0, rows=1, q='(type:harvest)', fq='+dataset_type:harvest', sort='metadata_created asc')),
        mock.call().json(),
    ]
    mock_requests.reset_mock()

    # Second page
    ckan.get_full_harvest_source = mock.Mock(return_value=expected_harvest_source_2)
    mock_requests.return_value = mock_response(data={
        'success': True,
        'result': {
            'count': 2,
            'results': [
                {
                    'title': 'dataset 2',
                    'name': 'dataset-2',
                    'state': 'active',
                    'source_type': 'ckan',
                },
            ],
        },
    })
    assert next(harvest_sources) == expected_harvest_source_2
    assert mock_requests.mock_calls == [
        api_call('/api/3/action/package_search', params=dict(start=1, rows=1, q='(type:harvest)', fq='+dataset_type:harvest', sort='metadata_created asc')),
        mock.call().json(),
    ]
