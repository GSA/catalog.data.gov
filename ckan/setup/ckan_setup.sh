#!/bin/bash

# Comes from https://github.com/okfn/docker-ckan/blob/master/ckan-dev/2.9/setup/start_ckan_development.sh
# This replaces running commands as user ckan and
# allows the user to run any command they want after ckan is setup

# Install any local extensions in the src_extensions volume
echo "Looking for local extensions to install..."
echo "Extension dir contents:"
ls -la $SRC_EXTENSIONS_DIR
for i in $SRC_EXTENSIONS_DIR/*
do
    if [ -d $i ];
    then
        if [ -f $i/setup.py ];
        then
            cd $i
            echo "Found setup.py file in $i"
            # Uninstall any current implementation of the code
            echo uninstalling "${PWD##*/}"
            pip3 uninstall "${PWD##*/}"
            # Install the extension in editable mode
            pip3 install -e .
            cd $APP_DIR
        fi

        # Point `use` in test.ini to location of `test-core.ini`
        if [ -f $i/test.ini ];
        then
            echo "Updating \`test.ini\` reference to \`test-core.ini\` for plugin $i"
            ckan config-tool $i/test.ini "use = config:../../src/ckan/test-core.ini"
        fi
    fi
done

# Set debug to true
echo "Enabling debug mode"
ckan config-tool $CKAN_INI -s DEFAULT "debug = true"

# Update the plugins setting in the ini file with the values defined in the env var
echo "Loading the following plugins: $CKAN__PLUGINS"
ckan config-tool $CKAN_INI "ckan.plugins = $CKAN__PLUGINS"

# Update test-core.ini DB, SOLR & Redis settings
echo "Loading test settings into test-core.ini"
ckan config-tool $SRC_DIR/ckan/test-core.ini \
    "sqlalchemy.url = $TEST_CKAN_SQLALCHEMY_URL" \
    "ckan.datastore.write_url = $TEST_CKAN_DATASTORE_WRITE_URL" \
    "ckan.datastore.read_url = $TEST_CKAN_DATASTORE_READ_URL" \
    "solr_url = $TEST_CKAN_SOLR_URL" \
    "ckan.redis.url = $TEST_CKAN_REDIS_URL"

# SOLR takes a while to boot up in zookeeper mode, make sure it's up before
echo "Validating SOLR is up..."
NEXT_WAIT_TIME=0
until [ $NEXT_WAIT_TIME -eq 10 ] || curl --get --fail --quiet --location-trusted  --user $CKAN_SOLR_USER:$CKAN_SOLR_PASSWORD \
    $CKAN_SOLR_BASE_URL/solr/admin/collections \
    --data-urlencode action=list \
    --data-urlencode wt=json; do
    sleep $(( NEXT_WAIT_TIME++ ))
    echo "SOLR still not up, trying for the $NEXT_WAIT_TIME time"
done
[ $NEXT_WAIT_TIME -lt 10 ]

# Add ckan core to solr
/app/ckan/setup/migrate-solrcloud-schema.sh

# Run the prerun script to init CKAN and create the default admin user
python GSA_prerun.py

# Run any startup scripts provided by images extending this one
if [[ -d "/docker-entrypoint.d" ]]
then
    for f in /docker-entrypoint.d/*; do
        case "$f" in
            *.sh)     echo "$0: Running init file $f"; . "$f" ;;
            *.py)     echo "$0: Running init file $f"; python3 "$f"; echo ;;
            *)        echo "$0: Ignoring $f (not an sh or py file)" ;;
        esac
        echo
    done
fi

exec /app/ckan/setup/server_start.sh
