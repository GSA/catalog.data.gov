import pytest
from remote_ckan.lib import RemoteCKAN
from import_groups import import_groups
    

@pytest.mark.vcr()
def test_import_groups_1():
    """ Test import_groups script """

    ret = import_groups(
        origin_url='https://catalog.data.gov', 
        destination_url='https://ckan:5000',
        destination_api_key='2301-aw23-1114',
        user_agent='CKAN-harvest-source-importer 1.0',
        groups='agriculture8571,disasters', skip_groups='disasters')

    assert 'disasters' in ret['groups_skipped']
    assert 'agriculture8571' in ret['groups_processed']
    assert len(ret['groups_processed']) == 1
    assert len(ret['already_in_group']) == 8
    assert len(ret['added_to_group']) == 0
    assert len(ret['failed_to_add']) == 0


@pytest.mark.vcr()
def test_import_groups_2():
    """ Test import_groups script """

    ret = import_groups(
        origin_url='https://catalog.data.gov', 
        destination_url='https://ckan:5000',
        destination_api_key='2301-aw23-1114',
        user_agent='CKAN-harvest-source-importer 1.0',
        groups='law1129,disasters')

    assert len(ret['groups_skipped']) == 0
    assert len(ret['groups_processed']) == 2
    assert 'law1129' in ret['groups_processed']
    assert 'disasters' in ret['groups_processed']
    assert len(ret['already_in_group']) == 76
    assert len(ret['added_to_group']) == 0
    assert len(ret['failed_to_add']) == 0
