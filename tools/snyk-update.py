
import json
import os

# Load results
scan_file = open('scan.json')
scan = json.load(scan_file)
scan_file.close()

update = False

# Make changes to fixable results
remediations = scan['remediation']['pin']
for k, v in remediations.items():
    package, old_version = k.split('@')
    new_version = v['upgradeTo'].split('@')[1]
    print(package, old_version, new_version)

    # Check to see if package was explicitly included
    with open('ckan/requirements.in', 'r') as source:
        all_requirements = source.readlines()
    if package in ', '.join(all_requirements):
        update = True

    if update:
        # Remove old version
        os.system('sed -i "/^%s\\(=\\|>\\|$\\)/Id" ckan/requirements.in' % (package))
        # Add new version if it was already being specified
        os.system("echo '%s' >> ckan/requirements.in" % (package + ">=" + new_version))

# TODO: Handle unfixable results
