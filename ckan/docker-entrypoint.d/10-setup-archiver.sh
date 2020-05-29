echo "Setup Report database table"
paster --plugin=ckanext-report report initdb --config=mysite.ini

echo "Setup Archiver database table"
paster --plugin=ckanext-archiver archiver init --config=$CKAN_INI
paster --plugin=ckanext-report report initdb --config=$CKAN_INI
