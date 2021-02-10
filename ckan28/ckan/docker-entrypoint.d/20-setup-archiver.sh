echo "Setup Report database table"
paster --plugin=ckanext-report report initdb --config=$CKAN_INI

echo "Setup Archiver database table"
paster --plugin=ckanext-archiver archiver init --config=$CKAN_INI
