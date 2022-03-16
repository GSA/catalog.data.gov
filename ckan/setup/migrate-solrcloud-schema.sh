#!/bin/bash
set -e

COLLECTION_NAME=${1:-ckan}

# https://gist.github.com/adborden/4b2ecc9d679556ac436b0616d9ddd3b2

# error out if environment variables not set
if [[ -z "$CKAN_SOLR_BASE_URL" ]]; then
    echo "Must provide CKAN_SOLR_BASE_URL in environment" 1>&2
    exit 1
elif [[ -z "$CKAN_SOLR_USER" ]]; then
    echo "Must provide CKAN_SOLR_USER in environment" 1>&2
    exit 1
elif [[ -z "$CKAN_SOLR_PASSWORD" ]]; then
    echo "Must provide CKAN_SOLR_PASSWORD in environment" 1>&2
    exit 1
fi

# Check if the solr core exists.
if ! (curl --get --fail --location-trusted  --user $CKAN_SOLR_USER:$CKAN_SOLR_PASSWORD \
    $CKAN_SOLR_BASE_URL/solr/admin/collections \
    --data-urlencode action=list \
    --data-urlencode wt=json | grep -q $COLLECTION_NAME); then

    cd $(dirname $0)/solr

    CKAN_BRANCH="dev-v2.9"
    curl https://raw.githubusercontent.com/ckan/ckan/$CKAN_BRANCH/ckan/config/solr/schema.xml -o managed-schema

    # Fix from https://github.com/ckan/ckan/issues/5585#issuecomment-953586246
    sed -i "s/<defaultSearchField>text<\/defaultSearchField>/<df>text<\/df>/" managed-schema
    sed -i "s/<solrQueryParser defaultOperator=\"AND\"\/>/<solrQueryParser q.op=\"AND\"\/>/" managed-schema

    # Zip solr configSet
    zip ckan_2.9_solr_config.zip \
      managed-schema solrconfig.xml protwords.txt stopwords.txt  synonyms.txt

    echo "Uploading config set..."
    curl --fail  --location-trusted --user $CKAN_SOLR_USER:$CKAN_SOLR_PASSWORD \
        "$CKAN_SOLR_BASE_URL/solr/admin/configs?action=upload&name=$COLLECTION_NAME" \
        --data-binary @ckan_2.9_solr_config.zip --header 'Content-Type:application/octet-stream'

    echo "Creating solr collection..."
    if [[ "$COLLECTION_NAME" = "ckan_local" ]]; then
      curl --fail  --location-trusted --user $CKAN_SOLR_USER:$CKAN_SOLR_PASSWORD \
        "$CKAN_SOLR_BASE_URL/solr/admin/collections?action=create&name=$COLLECTION_NAME&collection.configName=$COLLECTION_NAME&numShards=1&nrtReplicas=2" \
        -X POST
    else
      curl --fail  --location-trusted --user $CKAN_SOLR_USER:$CKAN_SOLR_PASSWORD \
        "$CKAN_SOLR_BASE_URL/solr/admin/collections?action=create&name=$COLLECTION_NAME&collection.configName=$COLLECTION_NAME&numShards=1&nrtReplicas=3&pullReplicas=2" \
        -X POST
    fi

    cd -
fi
