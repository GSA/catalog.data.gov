set -e

echo "Init Harvest database tables"
ckan harvester initdb

echo "turn on gather and fetch workers"
ckan harvester fetch-consumer &
ckan harvester gather-consumer &

echo "check harvest job completion every minute"
harvester_check="*/1 * * * * ckan harvester run &> /tmp/harvester_run.log"
(crontab -u $(whoami) -l; echo "$harvester_check" ) | crontab -u $(whoami) -
