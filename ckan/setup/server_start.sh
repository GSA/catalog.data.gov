#!/bin/bash

IF test -f ".env"; then
    set -o allexport; source .env; set +o allexport
fi

# Run web application
$CKAN_PY_ENV/newrelic-admin run-program $CKAN_PY_ENV/gunicorn --worker-class gevent --paste $CKAN_INI "$@"