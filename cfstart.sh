#!/bin/bash

set -o errexit
set -o pipefail
# set -o nounset # This option conflicts with the use of regex matching and $BASH_REMATCH

# Utilize paster command, can remove when on ckan 2.9
function ckan () {
    paster --plugin=ckan "$@"
}

# At this point we expect that you've already setup these environment variables:
#   SOLR_URL <solr_url>

# We need to know the application name ...

APP_NAME=$(echo $VCAP_APPLICATION | jq -r '.application_name')

# We need the public URL for the configuration file
APP_URL=$(echo $VCAP_APPLICATION | jq -r '.application_uris[0]')

# ... from which we can guess the service names

SVC_DATABASE="${APP_NAME}-db"
SVC_REDIS="${APP_NAME}-redis"
SVC_SECRETS="${APP_NAME}-secrets"

# ckan reads some environment variables... https://docs.ckan.org/en/2.8/maintaining/configuration.html#environment-variables
export CKAN_SQLALCHEMY_URL=$(echo $VCAP_SERVICES | jq -r --arg SVC_DATABASE $SVC_DATABASE '.[][] | select(.name == $SVC_DATABASE) | .credentials.uri')
export CKAN_SITE_URL=https://$APP_URL
export CKAN_SOLR_URL=$SOLR_URL
export CKAN_STORAGE_PATH=/home/vcap/app/files

# We need the redis credentials for ckan to access redis, and we need to build the url
REDIS_HOST=$(echo $VCAP_SERVICES | jq -r --arg SVC_REDIS $SVC_REDIS '.[][] | select(.name == $SVC_REDIS) | .credentials.host')
REDIS_PASSWORD=$(echo $VCAP_SERVICES | jq -r --arg SVC_REDIS $SVC_REDIS '.[][] | select(.name == $SVC_REDIS) | .credentials.password')
REDIS_PORT=$(echo $VCAP_SERVICES | jq -r --arg SVC_REDIS $SVC_REDIS '.[][] | select(.name == $SVC_REDIS) | .credentials.port')
export CKAN_REDIS_URL=rediss://:$REDIS_PASSWORD@$REDIS_HOST:$REDIS_PORT

# We need the secret credentials for various application components (DB configuration, license keys, etc)
export CKAN___BEAKER__SESSION__SECRET=$(echo $VCAP_SERVICES | jq -r --arg SVC_SECRETS $SVC_SECRETS '.[][] | select(.name == $SVC_SECRETS) | .credentials.CKAN___BEAKER__SESSION__SECRET')

# ckanext-envvars can read environment variables with the correct format...

# Setting up PostGIS
DATABASE_URL=$CKAN_SQLALCHEMY_URL ./configure-postgis.py

# Edit the config file to use our values
ckan config-tool ckan/setup/production.ini -s server:main -e port=${PORT}
# ckan config-tool ckan/setup/production.ini \
#     "ckan.storage_path=/home/vcap/app/files"

# Run migrations
# paster --plugin=ckan db upgrade -c ckan/setup/production.ini
ckan db upgrade -c ckan/setup/production.ini 

# Fire it up!
# exec ckan -c ckan/setup/production.ini run -H 0.0.0.0 -p $PORT
exec paster --plugin=ckan serve ckan/setup/production.ini

