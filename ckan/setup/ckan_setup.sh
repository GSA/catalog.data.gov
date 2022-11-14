#!/bin/bash

set -e

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
            pip3 uninstall -y "${PWD##*/}"
            # Install the extension in editable mode
            pip3 install -e .
            cd $APP_DIR
        fi
    fi
done

echo "Enabling debug mode"
ckan config-tool $CKAN_INI -s DEFAULT "debug = true"

# Update the plugins setting in the ini file with the values defined in the env var
echo "Loading the following plugins: $CKAN__PLUGINS"
ckan config-tool $CKAN_INI "ckan.plugins = $CKAN__PLUGINS"

# Run the prerun script to init CKAN and create the default admin user
pipenv run python /srv/app/prerun.py

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
