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
CKAN_ORG="ckan"
CKAN_BRANCH="2.8"

wget -O full_requirements.txt https://raw.githubusercontent.com/GSA/catalog.data.gov/fcs/ckan/requirements.txt
wget https://raw.githubusercontent.com/$CKAN_ORG/ckan/$CKAN_BRANCH/test-core.ini
wget https://raw.githubusercontent.com/$CKAN_ORG/ckan/$CKAN_BRANCH/ckan/config/who.ini

echo "-----------------------------------------------------------------"
echo "Installing CKAN and its Python dependencies..."

pip install pip==20.3.3
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
sudo wget -O /etc/solr/conf/schema.xml https://raw.githubusercontent.com/GSA/catalog.data.gov/fcs/solr/schema.xml
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

echo "-----------------------------------------------------------------"
echo "Installing locations table"
DEST_FOLDER=/tmp
HOST=localhost
DB_NAME=ckan_test
DB_USER=ckan_default
PASS=pass

echo "Downloading locations table"
wget https://github.com/GSA/datagov-deploy/raw/71936f004be1882a506362670b82c710c64ef796/ansible/roles/software/ec2/ansible/files/locations.sql.gz -O $DEST_FOLDER/locations.sql.gz

echo "Creating locations table"
gunzip -c ${DEST_FOLDER}/locations.sql.gz | PGPASSWORD=${PASS} psql -h $HOST -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1

echo "Cleaning"
rm -f $DEST_FOLDER/locations.sql.gz

echo "travis-build.bash is done."
