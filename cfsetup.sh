#!/bin/bash

set -o errexit
set -o pipefail
# TODO: convert to .profile
echo "Running setup script..."

function vcap_get_service () {
  local path name
  name="$1"
  path="$2"
  service_name=${APP_NAME}-${name}
  echo $VCAP_SERVICES | jq --raw-output --arg service_name "$service_name" ".[][] | select(.name == \$service_name) | $path"
}

# Create a staging area for secrets and files
CONFIG_DIR=$(mktemp -d)
SHARED_DIR=$(mktemp -d)

# We need to know the application name ...
APP_NAME=$(echo $VCAP_APPLICATION | jq -r '.application_name')
APP_URL=$(echo $VCAP_APPLICATION | jq -r '.application_uris[0]')

# Extract credentials from VCAP_SERVICES
REDIS_HOST=$(vcap_get_service redis .credentials.host)
REDIS_PASSWORD=$(vcap_get_service redis .credentials.password)
REDIS_PORT=$(vcap_get_service redis .credentials.port)
SAML2_PRIVATE_KEY=$(vcap_get_service secrets .credentials.SAML2_PRIVATE_KEY)

# Export settings for CKAN via ckanext-envvars
export CKAN_REDIS_URL=rediss://:$REDIS_PASSWORD@$REDIS_HOST:$REDIS_PORT
export CKAN_SITE_URL=https://$APP_URL
export CKAN_SQLALCHEMY_URL=$(vcap_get_service db .credentials.uri)
export CKAN_STORAGE_PATH=${SHARED_DIR}/files
export CKAN___BEAKER__SESSION__SECRET=$(vcap_get_service secrets .credentials.CKAN___BEAKER__SESSION__SECRET)
export CKAN___BEAKER__SESSION__URL=${CKAN_SQLALCHEMY_URL}
export CKANEXT__SAML2AUTH__KEY_FILE_PATH=${CONFIG_DIR}/saml2_key.pem
export CKANEXT__SAML2AUTH__CERT_FILE_PATH=${CONFIG_DIR}/saml2_certificate.pem

export NEW_RELIC_LICENSE_KEY=$(vcap_get_service secrets .credentials.NEW_RELIC_LICENSE_KEY)

# Add saxon jar for transformation from CSDGM/FGDC to ISO
curl https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/9.9.1-7/Saxon-HE-9.9.1-7.jar --output /usr/lib/jvm/java-11-openjdk/saxon/saxon.jar

# Write out any files and directories
mkdir -p $CKAN_STORAGE_PATH
echo "$SAML2_PRIVATE_KEY" | base64 --decode > $CKANEXT__SAML2AUTH__KEY_FILE_PATH
echo "$SAML2_CERTIFICATE" > $CKANEXT__SAML2AUTH__CERT_FILE_PATH

# Setting up PostGIS
echo Setting up PostGIS
DATABASE_URL=$CKAN_SQLALCHEMY_URL python3 configure-postgis.py

# Edit the config file to use our values
export CKAN_INI=config/production.ini
ckan config-tool $CKAN_INI -s server:main -e port=${PORT}

echo Running ckan setup commands

# Run migrations
ckan db upgrade
ckan harvester initdb
# TODO: add once extensions integrated
# ckan report initdb
# ckan archiver init
# ckan qa init

# Run your command (typically harvester job or server)
echo Running given command: $1 $2
exec $@
