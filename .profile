#!/bin/bash

set -o errexit
set -o pipefail

echo "Running setup script..."

echo "Setting CA Bundle.."
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

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
    cp ./ckan/setup/cacerts ../deps/0/apt/etc/ssl/certs/java/cacerts
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
export REAL_NAME=$(echo $VCAP_APPLICATION | jq -r '.application_name')
if [[ $APP_NAME = "catalog-web" ]] || \
   [[ $APP_NAME = "catalog-admin" ]] || \
   [[ $APP_NAME = "catalog-gather" ]] || \
   [[ $APP_NAME = "catalog-fetch" ]]
then
  APP_NAME=catalog
fi

# Extract credentials from VCAP_SERVICES
export REDIS_HOST=$(vcap_get_service redis .credentials.host)
export REDIS_PASSWORD=$(vcap_get_service redis .credentials.password)
export REDIS_PORT=$(vcap_get_service redis .credentials.port)
export SAML2_PRIVATE_KEY=$(vcap_get_service secrets .credentials.SAML2_PRIVATE_KEY)
export CKANEXT__SAML2AUTH__IDP_METADATA__LOCAL_PATH="${HOME}/${CKANEXT__SAML2AUTH__IDP_METADATA__LOCAL_PATH}"

# Export settings for CKAN via ckanext-envvars
export CKAN_REDIS_URL=rediss://:$REDIS_PASSWORD@$REDIS_HOST:$REDIS_PORT
export CKAN_SQLALCHEMY_URL=$(vcap_get_service db .credentials.uri)
export CKAN___SQLALCHEMY__POOL_SIZE=250
export CKAN___SQLALCHEMY__MAX_OVERFLOW=500

export CKAN_STORAGE_PATH=${SHARED_DIR}/files
export CKAN___BEAKER__SESSION__SECRET=$(vcap_get_service secrets .credentials.CKAN___BEAKER__SESSION__SECRET)
export CKAN___BEAKER__SESSION__URL=${CKAN_SQLALCHEMY_URL}
export CKANEXT__SAML2AUTH__KEY_FILE_PATH=${CONFIG_DIR}/saml2_key.pem
export CKANEXT__SAML2AUTH__CERT_FILE_PATH=${CONFIG_DIR}/saml2_certificate.pem

# Use follower url for web instances; leader url for gather and fetch instances
if [[ $REAL_NAME = "catalog-admin" ]] || \
   [[ $REAL_NAME = "catalog-gather" ]] || \
   [[ $REAL_NAME = "catalog-fetch" ]]
then
  export CKAN_SOLR_BASE_URL=https://$(vcap_get_service solr .credentials.domain)
else
  export CKAN_SOLR_BASE_URL=https://$(vcap_get_service solr .credentials.domain_replica)
fi
export CKAN_SOLR_USER=$(vcap_get_service solr .credentials.username)
export CKAN_SOLR_PASSWORD=$(vcap_get_service solr .credentials.password)

export NEW_RELIC_LICENSE_KEY=$(vcap_get_service secrets .credentials.NEW_RELIC_LICENSE_KEY)
# Get sysadmins list by a user-provided-service per environment
export CKANEXT__SAML2AUTH__SYSADMINS_LIST=$(echo $VCAP_SERVICES | jq --raw-output ".[][] | select(.name == \"sysadmin-users\") | .credentials.CKANEXT__SAML2AUTH__SYSADMINS_LIST")

# SMTP Settings
export CKAN_SMTP_SERVER=$(vcap_get_service smtp .credentials.smtp_server)
export CKAN_SMTP_STARTTLS=True
export CKAN_SMTP_USER=$(vcap_get_service smtp .credentials.smtp_user)
export CKAN_SMTP_PASSWORD=$(vcap_get_service smtp .credentials.smtp_password)
export CKAN_SMTP_MAIL_FROM=harvester@$(vcap_get_service smtp .credentials.domain_arn | grep -o "ses-[[:alnum:]]\+.ssb.data.gov")
export CKAN_SMTP_REPLY_TO=datagovhelp@gsa.gov

# S3 settings
# Use ckanext-envvars to import other configurations...
export CKANEXT__S3SITEMAP__REGION_NAME=$(vcap_get_service s3 .credentials.region)
export CKANEXT__S3SITEMAP__HOST_NAME=https://s3-$CKANEXT__S3FILESTORE__REGION_NAME.amazonaws.com
export CKANEXT__S3SITEMAP__AWS_ACCESS_KEY_ID=$(vcap_get_service s3 .credentials.access_key_id)
export CKANEXT__S3SITEMAP__AWS_SECRET_ACCESS_KEY=$(vcap_get_service s3 .credentials.secret_access_key)
export CKANEXT__S3SITEMAP__AWS_BUCKET_NAME=$(vcap_get_service s3 .credentials.bucket)
export CKANEXT__S3SITEMAP__AWS_STORAGE_PATH=catalog/sitemap
export CKANEXT__S3SITEMAP__ENDPOINT_URL=https://$(vcap_get_service s3 .credentials.endpoint)

# Set up the collection in Solr
echo Setting up Solr collection
export SOLR_COLLECTION=ckan
# ./ckan/setup/migrate-solrcloud-schema.sh $SOLR_COLLECTION
export CKAN_SOLR_URL=$CKAN_SOLR_BASE_URL/solr/$SOLR_COLLECTION

# Explicitly don't proxy solr,
# Reference: https://github.com/ckan/ckan/issues/3653
export NO_PROXY=$NO_PROXY,$CKAN_SOLR_URL

# Write out any files and directories
mkdir -p $CKAN_STORAGE_PATH
echo "$SAML2_PRIVATE_KEY" | base64 --decode > $CKANEXT__SAML2AUTH__KEY_FILE_PATH
echo "$SAML2_CERTIFICATE" > $CKANEXT__SAML2AUTH__CERT_FILE_PATH

# Setting up PostGIS
echo Setting up PostGIS
DATABASE_URL=$CKAN_SQLALCHEMY_URL python3 configure-postgis.py

# Edit the config file to use our values
export CKAN_INI="${HOME}/ckan/setup/ckan.ini"
# ckan config-tool $CKAN_INI -s server:main -e port=${PORT}
ckan config-tool $CKAN_INI -s DEFAULT -e debug=false

echo Running ckan setup commands

if [[ $MIGRATE_DB = 'True' ]]; then
  # Run migrations
  ckan db upgrade
  ckan harvester initdb
  ckan archiver init
  ckan report initdb
  ckan qa init
fi
