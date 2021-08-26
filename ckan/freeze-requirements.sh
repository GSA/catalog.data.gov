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

echo "-e git+https://github.com/asl2/PyZ3950.git@c2282c73182cef2beca0f65b1eb7699c9b24512e#egg=PyZ3950" >> requirements.txt

poetry show --tree
chown ${USER_ID}:${GROUP_ID} poetry.lock requirements.txt

