#!/bin/bash 

# https://gist.github.com/adborden/4b2ecc9d679556ac436b0616d9ddd3b2

SOLR_URL='https://default-solr-6bb1c3054ccac59d-solrcloud.7f36d1b4-dad4-4d1b-90c9-f7014c20d9c9.ssb-dev.data.gov/solr'

# Check if the solr core exists.
if ! (curl --get --fail --silent http://solr:8983/solr/admin/cores \
    --data-urlencode action=status \
    --data-urlencode core=inventory | grep -q segmentsFileSizeInBytes); then

    # Create the solr core
    curl -v --get --fail --silent http://solr:8983/solr/admin/cores \
    --data-urlencode action=create \
    --data-urlencode name=inventory \
    --data-urlencode configSet=ckan2_8

    # Zip solr configSet
    zip ckan_2.9_solr_config.zip \
        currency.xml  elevate.xml  protwords.txt  schema.xml  solrconfig.xml stopwords.txt  synonyms.txt

    # Upload configSet
    curl -v --user $SOLR_CLOUD_CREDS \
        "$SOLR_URL/admin/configs?action=upload&name=ckan_v1" \
        --data-binary @ckan_2.9_solr_config.zip --header 'Content-Type:application/octet-stream'

    # Create solr collection
    curl -v --user $SOLR_CLOUD_CREDS \
        "$SOLR_URL/admin/collections?action=create&name=ckan&collection.configName=ckan_v1&numShards=1" \
        -X POST

    # Reload the core
    curl -v --get --fail --silent http://solr:8983/solr/admin/cores \
    --data-urlencode action=reload \
    --data-urlencode core=inventory
fi