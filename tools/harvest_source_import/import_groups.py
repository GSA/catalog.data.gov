"""
Migrate groups from one CKAN instance to another
/api/3/action/group_list (/api/3/action/group_list?all_fields=1)
"""

import argparse
import os
import time

from remote_ckan.lib import RemoteCKAN

parser = argparse.ArgumentParser()
parser.add_argument("--origin_url", type=str, default='https://catalog.data.gov', help="CKAN instance URL")
parser.add_argument("--names", type=str, default=None, help="Comma separated list of sources or path to a txt file with the list of harvest sources by name to test")
parser.add_argument("--user_agent", type=str, default='CKAN-harvest-source-importer 1.0 (https://github.com/GSA/catalog.data.gov/tree/master/tools/harvest_source_import)', help="User agent")
parser.add_argument("--destination_url", type=str, default='http://ckan:5000', help="CKAN destination instance URL")
parser.add_argument("--destination_api_key", type=str, help="CKAN destination instance API KEY")

args = parser.parse_args()

ckan = RemoteCKAN(url=args.origin_url, user_agent=args.user_agent)
ckan.set_destination(ckan_url=args.destination_url, ckan_api_key=args.destination_api_key)

for group in ckan.get_group_list():
    print('Group Found {}'.format(group))


if len(ckan.errors) > 0:
    print('*******\nWITH ERRORS\n*******')
    print('\n\t'.join(ckan.errors))

