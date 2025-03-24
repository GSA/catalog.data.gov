set -e

echo "Init Harvest database tables"
# datagov_harvest and harvest can't coexist in the same ckan instance
# so we have to temporarilly load harvest into plugin and create harvest tables.
tmp_config=$(mktemp)
sed '/^ckan.plugins/ s/datagov_harvest/harvest/g' /srv/app/ckan.ini > "$tmp_config"
ckan -c "$tmp_config" db upgrade -p harvest
rm "$tmp_config"

echo "turn on gather and fetch workers"
run_fetch () {
  until ckan harvester fetch-consumer; do
    sleep 1
  done
}
run_gather () {
  until ckan harvester gather-consumer; do
    sleep 1
  done
}
run_fetch &
run_gather &

echo "check harvest job completion every 10 secs"
check_harvester () {
  while true
  do
    ckan harvester run &> /tmp/harvester_run.log
    sleep 10
  done
}

check_harvester &
