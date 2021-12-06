#!/bin/bash
set -e

COLLECTION_NAME=${1:-ckan}

# https://gist.github.com/adborden/4b2ecc9d679556ac436b0616d9ddd3b2

# error out if environment variables not set
if [[ -z "$CKAN_SOLR_URL" ]]; then
    echo "Must provide CKAN_SOLR_URL in environment" 1>&2
    exit 1
elif [[ -z "$CKAN_SOLR_USER" ]]; then
    echo "Must provide CKAN_SOLR_USER in environment" 1>&2
    exit 1
elif [[ -z "$CKAN_SOLR_PASSWORD" ]]; then
    echo "Must provide CKAN_SOLR_PASSWORD in environment" 1>&2
    exit 1
fi

# Check if the solr core exists.
if ! (curl --get --fail --location-trusted --silent --user $CKAN_SOLR_USER:$CKAN_SOLR_PASSWORD \
    $CKAN_SOLR_URL/solr/admin/collections \
    --data-urlencode action=list \
    --data-urlencode wt=json | grep -q $COLLECTION_NAME); then

    # Zip solr configSet
    zip ckan_2.9_solr_config.zip \
        currency.xml  elevate.xml  protwords.txt  schema.xml  solrconfig.xml stopwords.txt  synonyms.txt \
        > /dev/null

    echo "Uploading config set..."
    curl --fail --silent --location-trusted --user $CKAN_SOLR_USER:$CKAN_SOLR_PASSWORD \
        "$CKAN_SOLR_URL/solr/admin/configs?action=upload&name=$COLLECTION_NAME" \
        --data-binary @ckan_2.9_solr_config.zip --header 'Content-Type:application/octet-stream' \
        > /dev/null

    echo "Creating solr collection..."
    curl --fail --silent --location-trusted --user $CKAN_SOLR_USER:$CKAN_SOLR_PASSWORD \
        "$CKAN_SOLR_URL/solr/admin/collections?action=create&name=$COLLECTION_NAME&collection.configName=$COLLECTION_NAME&numShards=1" \
        -X POST \
        > /dev/null
fi