#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
# sleep 1000

# Run web application
# exec newrelic-admin run-program gunicorn -c "$DIR/gunicorn.conf.py" --worker-class gevent --paste $CKAN_INI "$@"
exec newrelic-admin run-program gunicorn "wsgi:application" --config "$DIR/gunicorn.conf.py" -b "0.0.0.0:$PORT" --chdir $DIR
