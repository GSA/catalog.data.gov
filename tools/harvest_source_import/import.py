'''
Harvest source import
'''

import argparse
from remote_ckan.lib import RemoteCKAN

parser = argparse.ArgumentParser()
parser.add_argument("--origin_url", type=str, default='https://catalog.data.gov', help="CKAN instance URL")
parser.add_argument("--source_type", type=str, default='ALL', help="Tipe of harvest source: ALL|datajson|csw|waf etc")
parser.add_argument("--user_agent", type=str, default='CKAN-harvest-source-importer 1.0', help="User agent")
args = parser.parse_args()

ckan = RemoteCKAN(url=args.origin_url, user_agent=args.user_agent)

harvest_sources = []
for hs in ckan.list_harvest_sources(source_type=args.source_type):
    harvest_sources.append(hs)

print('Finished: {} harvest sources'.format(len(harvest_sources)))
