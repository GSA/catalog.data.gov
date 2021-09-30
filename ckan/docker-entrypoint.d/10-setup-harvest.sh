echo "Init Harvest database tables"
ckan harvester initdb

echo "turn on gather and fetch workers"
ckan harvester fetch-consumer &
ckan harvester gather-consumer &

echo "check harvest job completion every minute, see harvest-check-cron"
crond -b -l 8 &