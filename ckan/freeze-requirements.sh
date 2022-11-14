#!/bin/bash

set -o errexit
set -o pipefail

pip3 install pipenv

cd /app/ckan
PIPENV_PIPFILE=/app/ckan/Pipfile

pipenv install
pipfile2req Pipfile.lock > requirements.txt
