
import json
import os

# Load results
scan_file = open('scan.json')
scan = json.load(scan_file)
scan_file.close()

# Make changes to fixable results
remediations = scan['remediation']['pin']
for k, v in remediations.items():
    package, old_version = k.split('@')
    new_version = v['upgradeTo'].split('@')[1]
    print(package, old_version, new_version)

    # TODO: Handle case when vulnerable package isn't explicitly in requirements.in

    # Remove old version
    os.system('sed -i "/^%s\\(=\\|>\\|$\\)/Id" ckan/requirements.in' % (package))
    # Add new version
    os.system("echo '%s' >> ckan/requirements.in" % (package + ">=" + new_version))

# TODO: Handle unfixable results
