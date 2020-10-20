#!/bin/bash

# Run web application
newrelic-admin run-program gunicorn --worker-class gevent --paste $CKAN_INI "$@"