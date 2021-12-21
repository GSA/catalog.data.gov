#!/bin/bash 

# This script installs some necessary .deb dependencies and then installs binary .whls for the packages
# specified in vendor-requirements.txt into the "vendor" directory. The actual process runs inside a Docker
# container; Docker is the only local prerequisite.

# Get the latest version of the cflinuxfs3 image
if [[ "$1" == "build" ]]; then
  docker build -t catalog-vendor .
fi

# The bind mount here enables us to write back to the host filesystem
docker run --mount type=bind,source="$(pwd)",target=/home/vcap/app --tmpfs /home/vcap/app/src --name cf_bash --rm -i catalog-vendor:latest  /bin/bash -eu <<EOF

# Go where the app files are
cd ~vcap/app

# As the VCAP user, cache .whls based on the frozen requirements for vendoring
su - vcap -c 'cd app && pip download -r requirements.txt --no-binary=:none: -d vendor --exists-action=w'

EOF
