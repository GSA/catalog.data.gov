#!/bin/bash

set -o errexit
set -o pipefail

function vcap_get_service () {
    local path name
    name="$1"
    path="$2"
    service_name=catalog-${name}
    echo $VCAP_SERVICES | jq --raw-output --arg service_name "$service_name" ".[][] | select(.name == \$service_name) | $path"
}

export APP_NAME=$(echo $VCAP_APPLICATION | jq -r '.application_name')
export SPACE_NAME=$(echo $VCAP_APPLICATION | jq -r '.space_name')

echo "Setting up proxy in $APP_NAME on $SPACE_NAME"

# only add auth to staging environment / otherwise turn it off
if [[ $APP_NAME = "catalog-proxy" ]] && \
[[ $SPACE_NAME = "staging" ]]
then
    echo "Setting proxy basic auth..."
    echo "$(vcap_get_service secrets .credentials.PROXY_AUTH.USERNAME):$(vcap_get_service secrets .credentials.PROXY_AUTH.PASSWORD)" > ${HOME}/etc/nginx/.htpasswd
    export BASIC_AUTH_ENABLED='"Catalog-Web restricted"' ;
else
    echo "Not setting proxy basic auth..."
    export BASIC_AUTH_ENABLED=off ;
fi
sed -i "s/auth_configured/${BASIC_AUTH_ENABLED}/" ./nginx.conf