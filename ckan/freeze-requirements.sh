#!/bin/bash

set -o errexit
set -o pipefail

pip3 install pipenv

cd /app/ckan
PIPENV_PIPFILE=/app/ckan/Pipfile

pipenv install
cat Pipfile.lock | jq -r '.default | to_entries[] | .key + .value.version' > requirements.txt
