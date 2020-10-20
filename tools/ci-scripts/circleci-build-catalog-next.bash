#!/bin/bash
set -e
echo "Building catalog next environment..."

echo "-----------------------------------------------------------------"
echo "Installing the packages that CKAN requires..."
sudo apt-get update -qq
sudo apt-get install solr-jetty libcommons-fileupload-java libpq-dev postgresql \
	 postgresql-contrib python-lxml postgresql-9.3-postgis-2.1 \
 	 python-dev libxml2-dev libxslt1-dev libgeos-c1 redis-server


echo "-----------------------------------------------------------------"
echo "Downliading settings"

wget -O full_requirements.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/master/ckan/requirements.txt
wget https://raw.githubusercontent.com/GSA/ckan/datagov-newcatalog/test-core.ini
wget https://raw.githubusercontent.com/GSA/ckan/datagov-newcatalog/ckan/config/who.ini

echo "-----------------------------------------------------------------"
echo "Installing CKAN and its Python dependencies..."

pip install --upgrade pip
pip install setuptools -U
pip install -r full_requirements.txt

# extra pip
pip install flask_debugtoolbar
pip install google_compute_engine

# dev requirements
pip install factory-boy==2.1.1
pip install mock==1.0.1

echo "-----------------------------------------------------------------"
echo "Setting up Solr..."
# solr is multicore for tests on ckan master now, but it's easier to run tests
# on Travis single-core still.
# see https://github.com/ckan/ckan/issues/2972
sed -i -e 's/solr_url.*/solr_url = http:\/\/127.0.0.1:8983\/solr/' test-core.ini
printf "NO_START=0\nJETTY_HOST=127.0.0.1\nJETTY_PORT=8983\nJAVA_HOME=$JAVA_HOME" | sudo tee /etc/default/jetty
sudo wget -O /etc/solr/conf/schema.xml https://raw.githubusercontent.com/GSA/ckan/datagov-newcatalog/ckan/config/solr/schema.xml
sudo service jetty restart

echo "-----------------------------------------------------------------"
echo "Creating the PostgreSQL user and database..."
sudo -u postgres psql -c "CREATE USER ckan_default WITH PASSWORD 'pass';"
sudo -u postgres psql -c "CREATE USER datastore_default WITH PASSWORD 'pass';"
sudo -u postgres psql -c 'CREATE DATABASE ckan_test WITH OWNER ckan_default;'
sudo -u postgres psql -c 'CREATE DATABASE datastore_test WITH OWNER datastore_default;'

echo "Setting up PostGIS on the database..."
sudo -u postgres psql -d ckan_test -c 'CREATE EXTENSION postgis;'
sudo -u postgres psql -d ckan_test -c 'ALTER VIEW geometry_columns OWNER TO ckan_default;'
sudo -u postgres psql -d ckan_test -c 'ALTER TABLE spatial_ref_sys OWNER TO ckan_default;'


echo "-----------------------------------------------------------------"
echo "Initialising the database..."
paster --plugin=ckan db init -c test-catalog-next.ini

echo "-----------------------------------------------------------------"
echo "Initializing Harvester"
paster --plugin=ckanext-harvest harvester initdb -c test-catalog-next.ini

echo "-----------------------------------------------------------------"
echo "Initializing Spatial"
paster --plugin=ckanext-spatial spatial initdb -c test-catalog-next.ini

echo "-----------------------------------------------------------------"
echo "Initializing Archiver"
paster --plugin=ckanext-archiver archiver init -c test-catalog-next.ini

echo "-----------------------------------------------------------------"
echo "Initializing Report"
paster --plugin=ckanext-report report initdb -c test-catalog-next.ini

echo "-----------------------------------------------------------------"
echo "Initializing QA"
paster --plugin=ckanext-qa qa init -c test-catalog-next.ini


echo "travis-build.bash is done."
