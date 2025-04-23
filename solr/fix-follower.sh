#!/bin/bash

# Fix Solr followers that don't have the correct admin username and password
#
# Requires the environment variables ADMIN_USERNAME and ADMIN_PASSWORD. The
# base URL for the follower is the first command line argument. To look for
# the username and password, check the definition of the solr-init-... task
# in the AWS Console for this ECS Cluster.
#
# Example usage:
# $ ADMIN_USERNAME=203985ba-e0eb-fbe9-bb22-7268b7052a8b ADMIN_PASSWORD=8yXD4Vyt1A27Roke solr/fix-follower.sh https://follower.solr-0024490c-f123.ssb.data.gov:9001

if [[ -z "${ADMIN_USERNAME}" ]]; then
  echo "Must set the environment variable ADMIN_USERNAME."
  exit 1
fi

if [[ -z "${ADMIN_PASSWORD}" ]]; then
  echo "Must set the environment variable ADMIN_PASSWORD."
  exit 1
fi

if [[ -z "$1" ]]; then
  echo "No argument supplied; provide the follower URL as the first argument."
  exit 1
fi

curl -v --user 'catalog:Bleeding-Edge' "$1/solr/admin/authentication" -H 'Content-type:application/json' \
  --data "{\"set-user\": {\"${ADMIN_USERNAME}\": \"${ADMIN_PASSWORD}\"}}"
curl -v --user 'catalog:Bleeding-Edge' "$1/solr/admin/authorization" -H 'Content-type:application/json' \
  --data "{\"set-user-role\": {\"${ADMIN_USERNAME}\": [\"admin\"]}}"
curl -v --user "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" "$1/solr/admin/authorization" -H 'Content-type:application/json' \
  --data '{"set-user-role": {"catalog": null}}'
curl -v --user "${ADMIN_USERNAME}:${ADMIN_PASSWORD}"  "$1/solr/admin/authentication" -H 'Content-type:application/json' \
  --data '{"delete-user": ["catalog"]}'
