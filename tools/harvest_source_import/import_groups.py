"""
Migrate groups from one CKAN instance to another
"""

import argparse
import json
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

not_found = []
for group in ckan.get_group_list():
    print('Group Found {}'.format(group))
    
    # create this group at destination
    ckan.create_group(group)
    
    # get all datasets from this group and (if exist) add dataset to this group
    full_group = ckan.get_full_group(group_name=group, include_datasets=True)

    print(json.dumps(full_group, indent=4))
    packages = full_group.get('packages', [])
    for package in packages:
        name = package['name']
        # if this dataset exists in the new CKAN instance we need to update to add this group
        package = ckan.get_full_package(name_or_id=name, url=args.destination_ur)
        if packages is None:
            not_found.append({'group': group, 'dataset_name': name})
        
        # check if the groups already exist at the destination package
        if group in [grp[name] for grp in package['groups']]:
            print('Group {} already exists for {}'.format(group, name))
            continue
        
        # TODO update the dataset at the new environment to set the group
        

if len(ckan.errors) > 0:
    print('*******\nWITH ERRORS\n*******')
    print('\n\t'.join(ckan.errors))

print('Datasets not found: {}'.format(len(not_found)))
for nf in not_found:
    print('\tDataset {} at group {}'.format(nf['dataset_name', nf['group']]))
