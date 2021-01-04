'''
Harvest source import
Import for a specific list of harvest source names or by a type of source.
'''

import argparse
import json
import os
import time

from remote_ckan.lib import RemoteCKAN


def import_sources(**args):

    ckan = RemoteCKAN(url=args['origin_url'], user_agent=args['user_agent'])
    ckan.set_destination(ckan_url=args['destination_url'], ckan_api_key=args['destination_api_key'])

    # define the final list of sources to import (from type o a list)
    sources_to_import = []

    if args['names'] is not None:
        # we get a list of names from a file or list of source names
        if os.path.isfile(args['names']):
            f = open(args['names'])
            names = f.read().splitlines()
            f.close()
        else:
            names = args['names'].split(',')

        if args['offset'] > 0:
            names = names[args['offset']:]
        if args['limit'] > 0:
            names = names[:args['limit']]

        source_list_position = 0
        for hs in [{'name': name} for name in names]:
            time.sleep(args['wait_for_show'])
            source_list_position = source_list_position + 1
            print('****** collecting {}: {} of {} sources'.format(hs['name'], source_list_position, len(names)))
            rhs = ckan.get_full_harvest_source(hs)
            if rhs is None:
                print('ERROR GETTING EXTERNAL SOURCE: {}'.format(hs['name']))
                continue
            sources_to_import.append(rhs)

    else:
        for hs in ckan.list_harvest_sources(source_type=args['source_type'], start=args['offset'], limit=args['limit']):
            sources_to_import.append(hs)

    source_list_position = 0
    for hs in sources_to_import:
        # Save this sources to destination CKAN

        source_list_position = source_list_position + 1
        print(' ****** creating {}: {} of {} sources'.format(hs['name'], source_list_position, len(sources_to_import)))
        if hs.get('error', False):
            print('Skipping failed source: {}'.format(hs['name']))
            continue
        
        skip_sources = [] if args.get('skip_sources_file', None) is None else json.load(open(args['skip_sources_file']))
        skip_orgs = [] if args.get('skip_orgs_file', None) is None else json.load(open(args['skip_orgs_file']))
        
        print(f'Sources to skip: {skip_sources} from {args["skip_sources_file"]}')
        print(f'Organizations to skip: {skip_orgs}')
        
        if hs['name'] in [h['name'] for h in skip_sources]:
            print('Skipping source')
            ckan.harvest_sources[hs['name']]['skipped'] = 'source'
            continue

        if hs['organization']['name'] in [org['name'] for org in skip_orgs]:
            print('Skipping organization')
            ckan.harvest_sources[hs['name']]['skipped'] = 'organization'
            continue
        
        time.sleep(args['wait_for_create'])
        ckan.create_harvest_source(data=hs)
        assert 'created' in ckan.harvest_sources[hs['name']].keys()
        assert 'updated' in ckan.harvest_sources[hs['name']].keys()
        assert 'error' in ckan.harvest_sources[hs['name']].keys()

    created = len([k for k, v in ckan.harvest_sources.items() if v.get('created', None)])
    updated = len([k for k, v in ckan.harvest_sources.items() if v.get('updated', None)])
    skipped_sources = len([k for k, v in ckan.harvest_sources.items() if v.get('skipped', None) == 'source'])
    skipped_orgs = len([k for k, v in ckan.harvest_sources.items() if v.get('skipped', None) == 'organization'])
    errors = len([k for k, v in ckan.harvest_sources.items() if v.get('error', None)])

    total = created + updated + errors + skipped_sources + skipped_orgs

    assert total == len(ckan.harvest_sources)

    if len(ckan.errors) > 0:
        print('*******\nWITH ERRORS\n*******')
        print('\n\t'.join(ckan.errors))

    print('Finished: {} harvest sources. {} Added, {} already exists, {} failed'.format(total, created, updated, errors))

    # return the final list
    return ckan.harvest_sources


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument("--origin_url", type=str, default='https://catalog.data.gov', help="CKAN instance URL")
    parser.add_argument("--source_type", type=str, default='ALL', help="Type of harvest source: ALL|datajson|csw|waf|arcgis|ckan|datajson|geoportal|single-doc|waf-collection|z3950")
    parser.add_argument("--names", type=str, default=None, help="Comma separated list of sources or path to a txt file with the list of harvest sources by name to test")
    parser.add_argument("--user_agent", type=str, default='CKAN-harvest-source-importer 1.0 (https://github.com/GSA/catalog.data.gov/tree/master/tools/harvest_source_import)', help="User agent")
    parser.add_argument("--destination_url", type=str, default='http://ckan:5000', help="CKAN destination instance URL")
    parser.add_argument("--destination_api_key", type=str, help="CKAN destination instance API KEY")
    parser.add_argument("--limit", type=int, default=0, help="Limit the amount of Harvest sources to import")
    parser.add_argument("--offset", type=int, default=0, help="Offset")
    parser.add_argument("--wait_for_show", type=int, default=1, help="Wait this number of seconds between API calls to prevent timeout")
    parser.add_argument("--wait_for_create", type=int, default=5, help="Wait this number of seconds between API calls to prevent timeout")
    parser.add_argument("--skip_sources_file", type=str, help="Path to a file with a list of sources to skip")
    parser.add_argument("--skip_orgs_file", type=str, help="Path to a file with a list of organizations to skip")

    args = parser.parse_args()

    import_sources(vars(args))
