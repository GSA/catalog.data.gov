'''
Harvest source checker
Use local environment to list and check sources
'''

import argparse
import subprocess
from remote_ckan.lib import RemoteCKAN

parser = argparse.ArgumentParser()
parser.add_argument("--source_type", type=str, default="ALL",
                    help="Type of harvest source: ALL|datajson|csw|waf|arcgis|"
                    "ckan|datajson|geoportal|single-doc|waf-collection|z3950")
parser.add_argument("--limit", type=int, default=0, help="Limit the amount of Harvest sources to check")
args = parser.parse_args()

# Check sources locally
ckan = RemoteCKAN(url='http://ckan:5000')

jobs_with_errors = []

file_name = f'source-checks-{args.source_type}.txt'
f = open(file_name, 'w')

for hs in ckan.list_harvest_sources(source_type=args.source_type, limit=args.limit):
    print(' ****** {}/{}'.format(len(ckan.harvest_sources), args.limit))
    
    command = (['docker-compose', 'exec', 'ckan', 
                'paster', '--plugin=ckanext-harvest', 
                'harvester', 'run_test',
                hs.get("id"), '--config=$CKAN_INI'])
    out = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT)

    stdout, stderr = out.communicate()
    info = 'Running check for...\n\nTitle: {}' \
           '\n\tURL: {}\n\tID: {}'.format(hs.get("title"), hs.get("url"), hs.get("id"))
    f.write(info)
    print(info)
    
    errors = []
    for line in stdout.splitlines():
        if 'error' in line.lower():
            errors.append(line)
    
    if len(errors) == 0:
        print('No errors')
        f.write('\tOK')
    else:
        print('Error(s) found.')
        
        txt_errors = '\n'.join(set(errors))
        errored_job = 'Job title: {}\n\tID: {}' \
                    '\n\tError(s): \n{}\n'.format(hs.get("title"), 
                                                    hs.get("id"), 
                                                    txt_errors)
        jobs_with_errors.append(errored_job)
        f.write(errored_job)
        
    f.write('\n================================\n\n')

errored_jobs = len(jobs_with_errors) 
finish = f'FINISHED: There were {errored_jobs} harvest jobs with errors'
f.write(finish)
print(finish)
f.close()
