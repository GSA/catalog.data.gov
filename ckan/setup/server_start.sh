#!/bin/bash

# Run web application
exec newrelic-admin run-program gunicorn --worker-class gevent --paste $CKAN_INI "$@"
