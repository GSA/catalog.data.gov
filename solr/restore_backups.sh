#!/bin/bash

# Restore last dated EFS backup
good_backup=`ls | grep aws-backup-restore | tail -1`
mv $good_backup/ckan /var/solr/data/ckan

# Remove any unused data
rm -rf /var/solr/data/aws-backup-restore*

# Download the main setup
wget -O common_setup.sh https://raw.githubusercontent.com/GSA/catalog.data.gov/main/solr/solr_setup.sh
chmod 755 common_setup.sh

# Run the main setup
./common_setup.sh
