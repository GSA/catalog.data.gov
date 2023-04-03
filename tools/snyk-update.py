
import json
import os

# Load results
scan_file = open('scan.json')
scan = json.load(scan_file)
scan_file.close()

# Make changes to fixable results
remediations = scan['remediation']['pin']
for k, v in remediations.items():
    update = False
    package, old_version = k.split('@')
    new_version = v['upgradeTo'].split('@')[1]
    print(package, old_version, new_version)

    # Check to see if package was explicitly included
    # If it was not, then we only care about updating
    # requirements.txt, not requirements.in
    # 'make update-dependencies' will update requirements.txt
    with open('ckan/requirements.in', 'r') as source:
        all_requirements = source.readlines()
    if package in ', '.join(all_requirements):
        update = True

    if update:
        os.system('sed -i "/^%s\\(=\\|>\\|$\\)/Id" ckan/requirements.in' % (package))
        os.system("echo '%s' >> ckan/requirements.in" % (package + ">=" + new_version))

# TODO: Handle unfixable results
