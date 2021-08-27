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

# sadness -- pyz3950 is so old that poetry can't make sense of it's setup.py, so
# we have to add the requirement manually

# echo "-e git+https://github.com/danizen/PyZ3950.git@6d44a4ab85c8bda3a7542c2c9efdfad46c830219#egg=PyZ3950" >> requirements.txt
sed 's/ckanext-datagovcatalog \@ git\+https\:\/\/github.com\/GSA\/ckanext-datagovcatalog.git\@main/-e git+https://github.com/GSA/ckanext-datagovcatalog.git@main#egg=ckanext-datagovcatalog/g' requirements.txt > requirements.txt

poetry show --tree
chown ${USER_ID}:${GROUP_ID} poetry.lock requirements.txt

