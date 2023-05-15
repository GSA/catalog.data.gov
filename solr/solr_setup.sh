#!/bin/bash

mkdir -p /tmp/ckan_config

# Remove any residual EFS backups
rm -rf /var/solr/data/aws-backup-restore*

# In case of ECS Task stop and start, we need to make sure the Solr Core on EFS is not locked for new Task to use it.
# We use SOLR simple locktype. This code block gives old Task up to 5 mins to clear the lock file on EFS before exit.
# If it's been more than 5 mins, it means the old Task crashes without clearing the lock. Then the lockfile is force deleted.
export lockpath="/var/solr/data/ckan/data/index*"
export flagfile="/var/solr/data/retry-flag";
[[ $(find $lockpath -name write.lock) && ! -f $flagfile ]] && { echo "Found lock file. Creating flag file"; touch $flagfile; sleep 10; };
[[ $(find $lockpath -name write.lock) && ! $(find $flagfile -mmin +5) ]] && { echo "Keep waiting"; exit 1; };
ls -lart /var/solr/data;
ls -lart /var/solr/data/ckan/data;
find $lockpath -name write.lock -delete;
rm -rf $flagfile;

logfile=/var/solr/logs/solr.log
# add a marker to the end of the log file
if [ -f "$logfile" ]; then
  echo "#### CORECHECK_MARKER" >> $logfile
fi

check_corelock() {
  # check LockObtainFailedException since last check marker
  awk -v RS='(^|\n)CORECHECK_MARKER"\n' 'END{printf "%s", $0}' $logfile | grep -q "LockObtainFailedException"
  if [ $? -eq 0 ]; then
    echo "Found LockObtainFailedException in log file. Quit solr."
    solr stop -p 8983
  else
    echo "#### CORECHECK_MARKER" >> $logfile
  fi
}

# Once started, it checks every 10 seconds for 10 minutes
run_check() {
  for ((i=0; i<60; i++)); do
    echo "checking core lock"
    [ -f "$logfile" ] && check_corelock
    sleep 10
  done
}

# Run core lock check in the background.
run_check &

# add solr config files for ckan 2.9
wget -O /tmp/ckan_config/schema.xml https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/managed-schema
wget -O /tmp/ckan_config/protwords.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/protwords.txt
wget -O /tmp/ckan_config/solrconfig.xml https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/solrconfig.xml
wget -O /tmp/ckan_config/solrconfig_follower.xml https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/solrconfig_follower.xml
wget -O /tmp/ckan_config/stopwords.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/stopwords.txt
wget -O /tmp/ckan_config/synonyms.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/synonyms.txt

# Check if users already exist
SECURITY_FILE=/var/solr/data/security.json
if [ -f "$SECURITY_FILE" ]; then
  echo "Solr authentication are set up already :)"
  exit 0;
fi

# add solr authentication
cat <<SOLRAUTH > $SECURITY_FILE
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

#  group user solr:solr is 8983:8983 in solr docker image
chown -R 8983:8983 /var/solr/data/
