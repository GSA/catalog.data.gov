#!/bin/bash

# Remove any restored EFS backups
rm -rf /var/solr/data/aws-backup-restore*

# Download the main setup
wget -O common_setup.sh https://raw.githubusercontent.com/GSA/catalog.data.gov/main/solr/solr_setup.sh
chmod 755 common_setup.sh

# Run the main setup
./common_setup.sh
