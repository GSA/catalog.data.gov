#!/bin/bash

set -o errexit
set -o pipefail

echo "Running setup script..."

echo "java setup"

export JAVA_HOME=/home/vcap/deps/0/apt/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin

# Setup saxon jar file on classpath
export CLASSPATH=$CLASSPATH:/home/vcap/deps/0/apt/usr/share/java/Saxon-HE.jar

# Copy our provided JKS cacerts to the expected location 
#
# TODO: Generate this file on the fly the way that ca-certificates-java package
#       does in the postinst script. We can make use of
#       ../deps/0/apt/usr/sbin/update-ca-certificates if needed, but it will require
#       wrangling env vars to point to the non-root locations that it expects to find.
if [ ! -f ../deps/0/apt/etc/ssl/certs/java/cacerts ]; then
    mkdir -p ../deps/0/apt/etc/ssl/certs/java
    cp ./config/cacerts ../deps/0/apt/etc/ssl/certs/java/cacerts
fi

# echo BEFORE:
# find /home/vcap/deps/0 -xtype l | wc -l
# find /home/vcap/deps/0 -xtype l

# Find any broken links pointing to /etc and point them to /home/vcap/deps/0/apt/etc instead
find /home/vcap/deps/0 -xtype l -exec bash -c 'target="$(readlink "{}")"; link="{}"; target="$(echo "$target" | sed "s+^/etc+/home/vcap/deps/0/apt/etc+")"; ln -Tfs "$target" "$link"' \;

# echo AFTER:
# find /home/vcap/deps/0 -xtype l | wc -l
# find /home/vcap/deps/0 -xtype l

# Test java + saxon installation with test transform:
# java net.sf.saxon.Transform fgdc-csdgm_sample.xml fgdcrse2iso19115-2.xslt

echo "CKAN config setup..."

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
export APP_NAME=$(echo $VCAP_APPLICATION | jq -r '.application_name')
export APP_URL=$(echo $VCAP_APPLICATION | jq -r '.application_uris[0]')

# Extract credentials from VCAP_SERVICES
export REDIS_HOST=$(vcap_get_service redis .credentials.host)
export REDIS_PASSWORD=$(vcap_get_service redis .credentials.password)
export REDIS_PORT=$(vcap_get_service redis .credentials.port)
export SAML2_PRIVATE_KEY=$(vcap_get_service secrets .credentials.SAML2_PRIVATE_KEY)

# Export settings for CKAN via ckanext-envvars
export CKAN_REDIS_URL=rediss://:$REDIS_PASSWORD@$REDIS_HOST:$REDIS_PORT
export CKAN_SITE_URL=https://$APP_URL
export CKAN_SQLALCHEMY_URL=$(vcap_get_service db .credentials.uri)
export CKAN_STORAGE_PATH=${SHARED_DIR}/files
export CKAN___BEAKER__SESSION__SECRET=$(vcap_get_service secrets .credentials.CKAN___BEAKER__SESSION__SECRET)
export CKAN___BEAKER__SESSION__URL=${CKAN_SQLALCHEMY_URL}
export CKANEXT__SAML2AUTH__KEY_FILE_PATH=${CONFIG_DIR}/saml2_key.pem
export CKANEXT__SAML2AUTH__CERT_FILE_PATH=${CONFIG_DIR}/saml2_certificate.pem
export CKAN_SOLR_URL=https://$(vcap_get_service solr .credentials.domain)/solr/ckan
export CKAN_SOLR_USER=$(vcap_get_service solr .credentials.username)
export CKAN_SOLR_PASSWORD=$(vcap_get_service solr .credentials.password)

export NEW_RELIC_LICENSE_KEY=$(vcap_get_service secrets .credentials.NEW_RELIC_LICENSE_KEY)
# Get sysadmins list by a user-provided-service per environment
export CKANEXT__SAML2AUTH__SYSADMINS_LIST=$(echo $VCAP_SERVICES | jq --raw-output ".[][] | select(.name == \"sysadmin-users\") | .credentials.CKANEXT__SAML2AUTH__SYSADMINS_LIST")

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