'''
Harvest source import
'''

import argparse
from remote_ckan.lib import RemoteCKAN

parser = argparse.ArgumentParser()
parser.add_argument("--origin_url", type=str, default='https://catalog.data.gov', help="CKAN instance URL")
parser.add_argument("--source_type", type=str, default='ALL', help="Type of harvest source: ALL|datajson|csw|waf|arcgis|ckan|datajson|geoportal|single-doc|waf-collection|z3950")
parser.add_argument("--user_agent", type=str, default='CKAN-harvest-source-importer 1.0 (https://github.com/GSA/catalog.data.gov/tree/master/tools/harvest_source_import)', help="User agent")
parser.add_argument("--destination_url", type=str, default='http://ckan:5000', help="CKAN destination instance URL")
parser.add_argument("--destination_api_key", type=str, help="CKAN destination instance API KEY")
parser.add_argument("--limit", type=int, default=0, help="Limit the amount of Harvest sources to import")

args = parser.parse_args()

ckan = RemoteCKAN(url=args.origin_url, user_agent=args.user_agent)
ckan.set_destination(ckan_url=args.destination_url, ckan_api_key=args.destination_api_key)

for hs in ckan.list_harvest_sources(source_type=args.source_type, limit=args.limit):
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

print('Finished: {} harvest sources. {} Added, {} already exists, {} failed'.format(total, created, updated, errors))

assert total == len(ckan.harvest_sources)

if len(ckan.errors) > 0:
    print('*******\nWITH ERRORS\n*******')
    print('\n\t'.join(ckan.errors))
