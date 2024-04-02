'''
Harvest source checker
Use local environment to list and check harvest sources
'''

import argparse
import csv
import json
import os
import time
import subprocess
from remote_ckan.lib import RemoteCKAN

parser = argparse.ArgumentParser()
parser.add_argument("--source_type", type=str, default="ALL",
                    help="Type of harvest source: ALL|datajson|csw|waf|arcgis|"
                    "ckan|datajson|geoportal|single-doc|waf-collection|z3950")
parser.add_argument("--limit", type=int, default=0, help="Limit the amount of Harvest sources to check")
parser.add_argument("--names_to_test", type=str, default=None, help="Comma separated list of sources or path to a txt file with the list of harvest sources by name to test")
parser.add_argument("--origin_url", type=str, default='https://catalog.data.gov', help="CKAN instance URL")
parser.add_argument("--user_agent", type=str, default='CKAN-harvest-source-importer 1.0 (https://github.com/GSA/catalog.data.gov/tree/master/tools/harvest_source_import)', help="User agent")
parser.add_argument("--destination_url", type=str, default='http://ckan:5000', help="CKAN destination instance URL")
parser.add_argument("--destination_api_key", type=str, help="CKAN destination instance API KEY")


args = parser.parse_args()

# We will chech locally from sources and import if not exists 
local_ckan = RemoteCKAN(url=args.destination_url)
remote_ckan = RemoteCKAN(url=args.origin_url)
remote_ckan.set_destination(ckan_url=args.destination_url, ckan_api_key=args.destination_api_key)

# we get a list of names from a file or list of source names 
if os.path.isfile(args.names_to_test):
    f = open(args.names_to_test)
    names = f.read().splitlines()
    f.close()
else:
    names = args.names_to_test.split(',')

report_file_name = f'report-checks.csv'
fieldnames = ['name', 'url', 'config', 'source_type', 'status', 'last_job_status',
              'added', 'updated', 'nulls', 'object_error_summary',
              'gather_error_summary', 'main_errors', 'time']
final_file = open(report_file_name, 'a')
writer = csv.DictWriter(final_file, fieldnames=fieldnames)
writer.writeheader()

c = 0
for name in names:
    c += 1
    print(' ****** {}/{}: {}'.format(c, len(names), name))

    # skips already checked sources
    file_name = f'source-checks-{args.source_type}-{name}.txt'
    full_path = os.path.join(remote_ckan.temp_data, file_name)
    if os.path.isfile(full_path):
        print(f'SKIP already checked source {args.source_type} {name}')
        continue

    row = {'name': name,'time': time.time()}

    # check if already exists locally
    hs = local_ckan.get_full_harvest_source(hs={'name': name})
    if hs is None:  # some error
        # not exists locally, import
        rhs = remote_ckan.get_full_harvest_source(hs={'name': name})
        if rhs is None:
            print(f'ERROR GETTING EXTERNAL SOURCE: {name}')
            row['status'] = 'Failed to get external source'
            writer.writerow(row)
            continue

        # save it locally
        remote_ckan.create_harvest_source(data=rhs)
        # get this new source data
        hs = local_ckan.get_full_harvest_source(hs={'name': name})

    title = hs['title']
    url = hs['url']
    sid = hs['id']
    name = hs['name']
    config = hs.get('config', {})

    info = f'Running check for...\n\nTitle: {title}' \
           f'\n\tURL: {url}\n\tID: {sid}\n\t' \
           f'Config: {config}'
    print(info)
    
    command = (['docker compose', 'exec', 'ckan', 
                'ckan', 'harvester', 'run_test',
                hs.get("id"), '--config=/app/ckan/setup/ckan.ini'])
    out = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT)

    stdout, stderr = out.communicate()
    # some errors are not captured by harvester
    main_errors = []
    if stderr is not None:
        main_errors.append(str(stderr))
    
    if 'Traceback (most recent call last):' in str(stdout):
        #take the last part of the text
        lines = stdout.splitlines()[-1:]
        slines = [l.decode('utf-8') for l in lines]
        main_errors += slines

    row['main_errors'] = '\n\t - '.join(main_errors)
    # analyze results using harvest source show
    full_hs = local_ckan.get_full_harvest_source(hs={'id': sid, 'name': name})
    
    hs_status = full_hs.get('status', {})
    last_job = hs_status.get('last_job', {})
    last_job_status = last_job.get('status', 'unknown')
    stats = last_job.get('stats', {'added': -1, 'updated': -1})
    added = stats['added']
    updated = stats['updated']
    nulls = stats.get('null', -1)

    print(f'job: {last_job_status}: Added/updated: {added}/{updated}')

    object_error_summary = last_job.get('object_error_summary', [])
    gather_error_summary = last_job.get('gather_error_summary', [])
    print(f'Object errors:')
    for oe in object_error_summary:
        print(f' - {oe}')
    
    print(f'Gather errors:')
    for ge in gather_error_summary:
        print(f' - {ge}')

    oes = [str(e) for e in object_error_summary]
    ges = [str(e) for e in gather_error_summary]
    row['status'] = 'Script OK'
    row['url'] = full_hs['url']
    row['config'] = full_hs['config']
    row['source_type'] = full_hs['source_type']
    row['last_job_status'] = last_job_status
    row['added'] = added
    row['updated'] = updated
    row['nulls'] = nulls
    row['object_error_summary'] = '\n\t - '.join(oes)
    row['gather_error_summary'] = '\n\t - '.join(ges)
    row['time'] = time.time()

    writer.writerow(row)

    f = open(full_path, 'w')
    f.write(info)
    f.write('\n**** stdout\n')
    f.write(stdout.decode('utf-8'))
    f.write('\n**** stderr\n')
    if stderr is not None:
        f.write(stderr.decode('utf-8'))
    f.close()

final_file.close()