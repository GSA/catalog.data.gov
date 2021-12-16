#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
# sleep 1000

# Run web application
# exec newrelic-admin run-program gunicorn -c "$DIR/gunicorn.conf.py" --worker-class gevent --paste $CKAN_INI "$@"
exec gunicorn "wsgi:application" --config "./gunicorn.conf.py" -b "0.0.0.0:$PORT"
