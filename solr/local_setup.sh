#!/bin/bash

set -e

# Setup ckan core config
/app/solr/solr_setup.sh

# Start solr
su -c "init-var-solr; precreate-core ckan /tmp/ckan_config; chown -R 8983:8983 /var/solr/data; solr-fg -Dsolr.lock.type=simple" -m solr
