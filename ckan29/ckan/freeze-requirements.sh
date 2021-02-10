#! /bin/bash

# Updates the Pipfile.lock and writes a "frozen" pip style requirements.txt to stdout
#
# Usage: freeze-requirements.sh <user id> <group id>
#
# <user id> and <group id> are passed to make sure Pipfile.lock is owned by the correct user!

USER_ID=$1
GROUP_ID=$2

cd /requirements

echo "Running poetry lock ..."
poetry lock -vvv
echo "Running poetry export ..."
poetry export -vvv --format requirements.txt --output requirements.txt --without-hashes

poetry show --tree
# chown ${USER_ID}:${GROUP_ID} poetry.lock requirements.txt

