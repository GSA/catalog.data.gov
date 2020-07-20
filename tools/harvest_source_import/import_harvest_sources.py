'''
Harvest source import
Import for a specific list of harvest source names or by a type of source.
'''

import argparse
import os
from remote_ckan.lib import RemoteCKAN

parser = argparse.ArgumentParser()
parser.add_argument("--origin_url", type=str, default='https://catalog.data.gov', help="CKAN instance URL")
parser.add_argument("--source_type", type=str, default='ALL', help="Type of harvest source: ALL|datajson|csw|waf|arcgis|ckan|datajson|geoportal|single-doc|waf-collection|z3950")
parser.add_argument("--names", type=str, default=None, help="Comma separated list of sources or path to a txt file with the list of harvest sources by name to test")
parser.add_argument("--user_agent", type=str, default='CKAN-harvest-source-importer 1.0 (https://github.com/GSA/catalog.data.gov/tree/master/tools/harvest_source_import)', help="User agent")
parser.add_argument("--destination_url", type=str, default='http://ckan:5000', help="CKAN destination instance URL")
parser.add_argument("--destination_api_key", type=str, help="CKAN destination instance API KEY")
parser.add_argument("--limit", type=int, default=0, help="Limit the amount of Harvest sources to import")
parser.add_argument("--offset", type=int, default=0, help="Offset")

args = parser.parse_args()

ckan = RemoteCKAN(url=args.origin_url, user_agent=args.user_agent)
ckan.set_destination(ckan_url=args.destination_url, ckan_api_key=args.destination_api_key)

# define the final list of sources to import (from type o a list)
sources_to_import = []

if args.names is not None:
    # we get a list of names from a file or list of source names 
    if os.path.isfile(args.names):
        f = open(args.names)
        names = f.read().splitlines()
        f.close()
    else:
        names = args.names.split(',')
    
    if args.offset > 0:
        names = names[args.offset:]
    if args.limit > 0:
        names = names[:args.limit]

    for hs in [{'name': name} for name in names]:
        rhs = ckan.get_full_harvest_source(hs)
        if rhs is None:
            print('ERROR GETTING EXTERNAL SOURCE: {}'.format(hs['name']))
            continue
        sources_to_import.append(rhs)    
        
else:
    for hs in ckan.list_harvest_sources(source_type=args.source_type, start=args.offset, limit=args.limit):
        sources_to_import.append(hs)

for hs in sources_to_import:
    print(' ****** {}/{}'.format(len(ckan.harvest_sources), args.limit))
    # save to destination CKAN    
    ckan.create_harvest_source(data=hs)
    assert 'created' in ckan.harvest_sources[hs['name']].keys()
    assert 'updated' in ckan.harvest_sources[hs['name']].keys()
    assert 'error' in ckan.harvest_sources[hs['name']].keys()

created = len([k for k, v in ckan.harvest_sources.items() if v['created'] ])
updated = len([k for k, v in ckan.harvest_sources.items() if v['updated'] ])
errors = len([k for k, v in ckan.harvest_sources.items() if v['error'] ])
total = created + updated + errors

assert total == len(ckan.harvest_sources)

if len(ckan.errors) > 0:
    print('*******\nWITH ERRORS\n*******')
    print('\n\t'.join(ckan.errors))

print('Finished: {} harvest sources. {} Added, {} already exists, {} failed'.format(total, created, updated, errors))
