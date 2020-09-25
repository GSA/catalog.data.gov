'''
Read Harvest source and write a CSV report
'''

import argparse
import csv
from remote_ckan.lib import RemoteCKAN

parser = argparse.ArgumentParser()
parser.add_argument("--origin_url", type=str, default='https://catalog.data.gov', help="CKAN instance URL")
parser.add_argument("--source_type", type=str, default='ALL', help="Type of harvest source: ALL|datajson|csw|waf etc")
parser.add_argument("--user_agent", type=str, default='CKAN-harvest-source-importer 1.0', help="User agent")
parser.add_argument("--limit", type=int, default=0, help="Limit the amount of Harvest sources to import")
args = parser.parse_args()

ckan = RemoteCKAN(url=args.origin_url, user_agent=args.user_agent)

csvfile = open(f'report-{args.source_type}.csv', 'w')
fieldnames = ['title', 'name', 'type', 'url', 'frequency',
              'job_count', 'total_datasets', 'last_job_errored', 'last_job_created',
              'last_job_finished', 'last_job_status']
writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

writer.writeheader()

harvest_sources = []
total = 0
for hs in ckan.list_harvest_sources(source_type=args.source_type):

    if args.limit > 0:
        if total >= args.limit:
            break

    harvest_sources.append(hs)
    status = hs.get('status', {})
    last_job = status.get('last_job', {})
    if last_job is None:
        last_job = {}
    stats = last_job.get('stats', {})

    row = {'title': hs.get('title', 'undefined'),
           'name': hs['name'],
           'type': hs.get('source_type', 'undefined'),
           'url': hs.get('url', 'undefined'),
           'frequency': hs.get('frequency', 'undefined'),
           'job_count': status.get('job_count', 'undefined'),
           'total_datasets': status.get('total_datasets', 'undefined'),
           'last_job_created': last_job.get('created', 'undefined'),
           'last_job_finished': last_job.get('finished', 'undefined'),
           'last_job_status': last_job.get('status', 'undefined'),
           'last_job_errored': stats.get('errored', 0),
        }
    writer.writerow(row)


print('Finished: {} harvest sources with {} error(s)'.format(len(harvest_sources), len(ckan.errors)))
if len(ckan.errors) > 0:
    print('*******\nWITH ERRORS\n*******')
    print('\n\t'.join(ckan.errors))
