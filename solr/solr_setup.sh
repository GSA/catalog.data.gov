#!/bin/bash

mkdir -p /tmp/ckan_config

# add solr authentication
cat <<SOLRAUTH > /var/solr/data/security.json
{
"authentication":{
   "blockUnknown": true,
   "class":"solr.BasicAuthPlugin",
   "credentials":{"catalog":"rJzrn+HooKn79Q+cfysdGKmMhJbtj0Q1bTokFud6f9o= eKuBUjAoBIkJAMYZxJU6HOKSchTAce+DoQrY5Vewu7I="},
   "realm":"data.gov users",
   "forwardCredentials": false
},
"authorization":{
   "class":"solr.RuleBasedAuthorizationPlugin",
   "permissions":[{"name":"security-edit",
      "role":"admin"}],
   "user-role":{"catalog":"admin"}
}}
SOLRAUTH

# add solr config files for ckan 2.9
wget -O /tmp/ckan_config/schema.xml https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/managed-schema
wget -O /tmp/ckan_config/protwords.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/protwords.txt
wget -O /tmp/ckan_config/solrconfig.xml https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/solrconfig.xml
wget -O /tmp/ckan_config/stopwords.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/stopwords.txt
wget -O /tmp/ckan_config/synonyms.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/synonyms.txt

#  group user solr:solr is 8983:8983 in solr docker image
chown -R 8983:8983 /var/solr/data/
