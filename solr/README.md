(Stolen from https://gist.github.com/adborden/4b2ecc9d679556ac436b0616d9ddd3b2)

1. Download this gist.
2. Zip up the solr config files
3. Upload the configSet
4. Create the solr collection


Zip the solr config files.

    $ zip ckan_2.9_solr_config.zip currency.xml  elevate.xml  protwords.txt  schema.xml  solrconfig.xml stopwords.txt  synonyms.txt

Upload the configSet.

    $ curl -v --user $SOLR_CLOUD_CREDS 'https://default-solr-6bb1c3054ccac59d-solrcloud.7f36d1b4-dad4-4d1b-90c9-f7014c20d9c9.ssb-dev.data.gov/solr/admin/configs?action=upload&name=ckan_v1' --data-binary @ckan_2.9_solr_config.zip --header 'Content-Type:application/octet-stream'

Create the solr collection.

    $ curl -v --user $SOLR_CLOUD_CREDS 'https://default-solr-6bb1c3054ccac59d-solrcloud.7f36d1b4-dad4-4d1b-90c9-f7014c20d9c9.ssb-dev.data.gov/solr/admin/collections?action=create&name=ckan&collection.configName=ckan_v1&numShards=1' -X POST
