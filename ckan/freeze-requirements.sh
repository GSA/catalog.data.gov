#!/bin/bash

set -o errexit
set -o pipefail

venv=$(mktemp -d)

function cleanup () {
  rm -rf $venv
}

trap cleanup EXIT

pip3 install virtualenv

virtualenv $venv
${venv}/bin/pip3 install setuptools==67.1.0
${venv}/bin/pip3 install -r /app/ckan/requirements.in

${venv}/bin/pip3 freeze --all > /app/ckan/requirements.txt
