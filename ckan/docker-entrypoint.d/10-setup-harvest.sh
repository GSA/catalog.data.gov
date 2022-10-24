set -e

echo "Init Harvest database tables"
ckan harvester initdb

echo "turn on gather and fetch workers"
ckan harvester fetch-consumer &
ckan harvester fetch-consumer &
ckan harvester gather-consumer &

echo "check harvest job completion every minute"
# Don't know why, but it needs to be here three times to work...
echo "*/1 * * * * ckan harvester run &> /tmp/harvester_run.log" | crontab -
echo "*/1 * * * * ckan harvester run &> /tmp/harvester_run.log" | crontab -
echo "*/1 * * * * ckan harvester run &> /tmp/harvester_run.log" | crontab -
/etc/init.d/cron start
