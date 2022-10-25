#!/bin/bash

set -e

# Setup ckan core config
/app/solr/solr_setup.sh

# Start solr
# Not sure how the path gets messed up, but it does :/ (so we have to fix it)
su -c "\
  export PATH=$PATH:/opt/docker-solr/scripts/:/opt/solr/bin/;\
  init-var-solr; precreate-core ckan /tmp/ckan_config; chown -R 8983:8983 /var/solr/data; solr-fg -Dsolr.lock.type=simple \
" -m solr
