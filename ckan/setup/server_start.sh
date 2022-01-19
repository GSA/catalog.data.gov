#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
# sleep 1000

# Run web application
# Each worker requires ~100MB of RAM
#   - 2 workers needs total 350MB RAM
#   - 4 Morkers needs total 550MB RAM
# Threads RAM requirement unknown at this time
# exec newrelic-admin run-program gunicorn -c "$DIR/gunicorn.conf.py" --worker-class gevent --paste $CKAN_INI "$@"
if [[ "$CKAN_SITE_URL" = "http://ckan:5000" ]]; then
  exec newrelic-admin run-program gunicorn "wsgi:application" --config "$DIR/gunicorn.conf.py" -b "0.0.0.0:$PORT" --chdir $DIR  --timeout 120 --workers 2
else
  exec newrelic-admin run-program gunicorn "wsgi:application" --config "$DIR/gunicorn.conf.py" -b "0.0.0.0:$PORT" --chdir $DIR  --timeout 120 --worker-class gevent --workers 4 --threads 4 --forwarded-allow-ips='*'
fi