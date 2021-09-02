#! /bin/bash

# Updates the Pipfile.lock and writes a "frozen" pip style requirements.txt to stdout
#
# Usage: freeze-requirements.sh <user id> <group id>
#
# <user id> and <group id> are passed to make sure Pipfile.lock is owned by the correct user!

set -e

USER_ID=$1
GROUP_ID=$2

# Make sure poetry is installed
pip3 install poetry

cd /requirements

echo "Running poetry lock ..."
poetry lock -vvv
echo "Running poetry export ..."
poetry export -vvv --format requirements.txt --output requirements.txt --without-hashes

# Sadness: poetry does not keep the "editable" mode that datagovcatalog is installed in.
# Replace the line with the necessary editable flag
sed -i 's/ckanext-datagovcatalog \@ git+https\:\/\/github.com\/GSA\/ckanext-datagovcatalog.git\@main/-e git+https:\/\/github.com\/GSA\/ckanext-datagovcatalog.git@main#egg=ckanext-datagovcatalog/g' requirements.txt
# TODO: add the rest of the editably installed extensions
# TODO: poetry does not pin to a github commit if given a branch;
#       need to figure out how to pin appropriately

poetry show --tree
chown ${USER_ID}:${GROUP_ID} poetry.lock requirements.txt

