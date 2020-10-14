"""
Migrate groups from one CKAN instance to another
"""
from remote_ckan.lib import RemoteCKAN


def import_groups(origin_url, user_agent, destination_url, 
                  destination_api_key, groups='ALL', skip_groups=''):
    ckan = RemoteCKAN(url=origin_url, user_agent=user_agent)
    ckan.set_destination(ckan_url=destination_url, ckan_api_key=destination_api_key)

    groups_processed = []
    groups_skipped = []
    not_found = []
    already_in_group = []
    added_to_group = []
    failed_to_add = [] 

    if groups == 'ALL':
        groups = ckan.get_group_list()
    else:
        groups = groups.split(',')

    for group in groups:
        print('Group Found {}'.format(group))

        if group in skip_groups.split(','):
            print('Skipping group')
            groups_skipped.append(group)
            continue

        groups_processed.append(group)
        
        # create this group at destination
        ckan.create_group(group)
        
        # get all datasets from this group and (if exist) add dataset to this group
        packages = ckan.get_datasets_in_group(group_name=group)
        for package in packages:
            name = package['name']
            # if this dataset exists in the new CKAN instance we need to update to add this group
            package = ckan.get_full_package(name_or_id=name, url=destination_url)
            if package is None:
                print('Package not found {}'.format(name))
                not_found.append({'group': group, 'dataset_name': name})
                continue
            
            # check if the groups already exist at the destination package
            if group in [grp['name'] for grp in package.get('groups', [])]:
                print('Group {} already exists for {}'.format(group, name))
                already_in_group.append(package['name'])
                continue
            
            # TODO update the dataset at the new environment to set the group
            package_update_url = f'{destination_url}/api/3/action/package_update'
            print(' ** Updating package {}'.format(name))

            package["groups"].append({'name': group})

            updated, status, error = ckan.request_ckan(url=package_update_url, method='POST', data=package)
            if updated:
                added_to_group.append(package['name'])
            else:
                failed_to_add.append(package['name'])

            print(' ** Updated ** Status {} ** Error {} **'.format(status, error))

    if len(ckan.errors) > 0:
        print('*******\nWITH ERRORS\n*******')
        print('\n\t'.join(ckan.errors))

    print('Datasets not found: {}'.format(len(not_found)))
    for nf in not_found:
        print('\tDataset {} at group {}'.format(nf['dataset_name'], nf['group']))

    print('Final results:')
    ret = {
        "groups_processed": groups_processed,
        "groups_skipped": groups_skipped,
        "not_found": not_found,
        "already_in_group": already_in_group,
        "added_to_group": added_to_group,
        "failed_to_add":failed_to_add 
    }

    print(ret)
    return ret

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--origin_url", type=str, default='https://catalog.data.gov', help="CKAN instance URL")
    parser.add_argument("--user_agent", type=str, default='CKAN-harvest-source-importer 1.0 (https://github.com/GSA/catalog.data.gov/tree/master/tools/harvest_source_import)', help="User agent")
    parser.add_argument("--destination_url", type=str, default='http://ckan:5000', help="CKAN destination instance URL")
    parser.add_argument("--destination_api_key", type=str, help="CKAN destination instance API KEY")
    parser.add_argument("--groups", type=str, default='ALL', help="'ALL' or the group names list separated by ','")
    parser.add_argument("--skip_groups", type=str, default='', help="Group names to skip list separated by ','")
    args = parser.parse_args()

    import_groups(**vars(args))