#!/bin/bash

mkdir -p /tmp/ckan_config

# Remove any residual EFS backups
rm -rf /var/solr/data/aws-backup-restore*

# In case of ECS Task stop and start, we need to make sure the Solr Core on EFS is not locked for new Task to use it.
# We use SOLR simple locktype. This code block gives old Task up to 5 mins to clear the lock file on EFS before exit.
# If it's been more than 5 mins, it means the old Task crashes without clearing the lock. Then the lockfile is force deleted.
export lockpath="/var/solr/data/ckan/data/index*"
export flagfile="/var/solr/data/retry-flag";
[[ $(find $lockpath -name write.lock) && ! -f $flagfile ]] && { echo "Found lock file. Creating flag file"; touch $flagfile; sleep 30; };
[[ $(find $lockpath -name write.lock) && ! $(find $flagfile -mmin +5) ]] && { echo "Keep waiting"; exit 1; };
ls -lart /var/solr/data;
ls -lart /var/solr/data/ckan/data;
find $lockpath -name write.lock -delete;
rm -rf $flagfile;

# add solr config files for ckan 2.9
wget -O /tmp/ckan_config/schema.xml https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/managed-schema
wget -O /tmp/ckan_config/protwords.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/protwords.txt
wget -O /tmp/ckan_config/solrconfig.xml https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/solrconfig.xml
wget -O /tmp/ckan_config/solrconfig_follower.xml https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/solrconfig_follower.xml
wget -O /tmp/ckan_config/stopwords.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/stopwords.txt
wget -O /tmp/ckan_config/synonyms.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/main/ckan/setup/solr/synonyms.txt

# check for multiple index folders and stop solr if so
# https://github.com/GSA/data.gov/issues/4138
check_index() {
  solr_url=http://localhost:8983/solr/

  # sleep until solr is ready with response code 200
  while true; do
    echo "In Check: Waiting for solr to be ready..."
    sleep 1
    status_code=$(curl --head --location --connect-timeout 5 --write-out %{http_code} --silent --output /dev/null ${solr_url})
    [[ "$status_code" -ne 200 ]] || break
  done

  echo "In Check: Solr is ready at ${solr_url}."

  # check multiple index folders
  # use the same lockpath="/var/solr/data/ckan/data/index*"
  export lockpath="/var/solr/data/ckan/data/index*"
  for i in {1..2}
  do
    index_count=$(find ${lockpath} -type d -name index* | wc -l)
    echo "In Check: Index folder count is ${index_count} on check ${i}."
    [[ "$index_count" -ne 1 ]] && echo "In Check: Stopping solr." && solr stop -p 8983
    # sleep and do it again just to be sure
    sleep 15
  done

  echo "In Check: Finished."
}
# Do check in the background
check_index &

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
