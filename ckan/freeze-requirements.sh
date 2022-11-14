#!/bin/bash

set -o errexit
set -o pipefail

pip3 install pipenv

cd /app/ckan
PIPENV_PIPFILE=/app/ckan/Pipfile

rm /app/ckan/Pipfile.lock
pipenv install
pipenv lock
