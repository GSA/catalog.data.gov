echo "Init Harvest database tables"
paster --plugin=ckanext-harvest harvester initdb --config=$CKAN_INI

echo "turn on gather and fetch workers"
paster --plugin=ckanext-harvest harvester fetch_consumer --config=$CKAN_INI &
paster --plugin=ckanext-harvest harvester gather_consumer --config=$CKAN_INI &