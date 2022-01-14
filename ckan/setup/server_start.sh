#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
# sleep 1000

# Run web application
# Each worker requires ~100MB of RAM
#   - 2 workers needs total 350MB RAM
#   - 4 Morkers needs total 550MB RAM
# Threads RAM requirement unknown at this time
exec newrelic-admin run-program gunicorn "wsgi:application" --config "$DIR/gunicorn.conf.py" -b "0.0.0.0:$PORT" --chdir $DIR  --timeout 120 --worker-class gevent --workers 4 --threads 4
