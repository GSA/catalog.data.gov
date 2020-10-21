#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if test -f "$DIR/.env"; then
    set -o allexport; source $DIR/.env; set +o allexport
fi

# Run web application
$CKAN_PY_ENV/newrelic-admin run-program $CKAN_PY_ENV/gunicorn --worker-class gevent --paste $CKAN_INI "$@"