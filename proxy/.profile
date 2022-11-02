#!/bin/bash

set -o errexit
set -o pipefail

function vcap_get_service () {
    local path name
    name="$1"
    path="$2"
    service_name=catalog-${name}
    echo "$VCAP_SERVICES" | jq --raw-output --arg service_name "$service_name" ".[][] | select(.name == \$service_name) | $path"
}

APP_NAME=$(echo "$VCAP_APPLICATION" | jq -r '.application_name')
export APP_NAME
SPACE_NAME=$(echo "$VCAP_APPLICATION" | jq -r '.space_name')
export SPACE_NAME
PROXY_AUTH_USERNAME=$(vcap_get_service secrets .credentials.PROXY_AUTH.USERNAME)
export PROXY_AUTH_USERNAME
PROXY_AUTH_PASSWORD=$(vcap_get_service secrets .credentials.PROXY_AUTH.PASSWORD)
export PROXY_AUTH_PASSWORD

echo "Setting up proxy in $APP_NAME on $SPACE_NAME"

if [[ "$PROXY_AUTH_USERNAME" = null ]] && [[ "$PROXY_AUTH_PASSWORD" = null ]]
then
    echo "Proxy auth and username absent, not setting proxy basic auth..."
    export BASIC_AUTH_ENABLED=off ;
else
    echo "Proxy auth and username are present, setting proxy basic auth..."
    echo "$PROXY_AUTH_USERNAME:$PROXY_AUTH_PASSWORD" > "${HOME}"/etc/nginx/.htpasswd
    export BASIC_AUTH_ENABLED='"Catalog-Web restricted"' ;
fi
sed -i "s/auth_configured/${BASIC_AUTH_ENABLED}/" ./nginx.conf

# sitemap config
# url constructed in nginx conf
# the jankiness and shame of this is immeasurable
S3_URL=$(vcap_get_service s3 .credentials.endpoint)
sed -i "s/s3_url_placeholder/${S3_URL}/" ./nginx-common.conf
S3_BUCKET=$(vcap_get_service s3 .credentials.bucket)
sed -i "s/s3_bucket_placeholder/${S3_BUCKET}/" ./nginx-common.conf
