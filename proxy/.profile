#!/bin/bash

set -o errexit
set -o pipefail

function vcap_get_service () {
    local path name
    name="$1"
    path="$2"
    service_name=${APP_NAME}-${name}
    echo $VCAP_SERVICES | jq --raw-output --arg service_name "$service_name" ".[][] | select(.name == \$service_name) | $path"
}

export APP_NAME=$(echo $VCAP_APPLICATION | jq -r '.application_name')
export SPACE_NAME=$(echo $VCAP_APPLICATION | jq -r '.space_name')

echo "Setting up proxy in $APP_NAME on $SPACE_NAME"

if [[ $APP_NAME = "tyler-catalog-proxy"]] && \
[[ $SPACE_NAME = "development"]]
then
    echo "Setting proxy username and password..."
    echo "$(vcap_get_service secrets .credentials.PROXY_AUTH.USERNAME):$(vcap_get_service secrets .credentials.PROXY_AUTH.PASSWORD)" > ${HOME}/etc/htpasswd
fi