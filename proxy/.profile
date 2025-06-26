#!/bin/bash

set -o errexit
set -o pipefail

function vcap_get_service () {
    local path name
    name="$1"
    path="$2"
    service_name=catalog-next-${name}
    echo "$VCAP_SERVICES" | jq --raw-output --arg service_name "$service_name" ".[][] | select(.name == \$service_name) | $path"
}

APP_NAME=$(echo "$VCAP_APPLICATION" | jq -r '.application_name')
export APP_NAME
SPACE_NAME=$(echo "$VCAP_APPLICATION" | jq -r '.space_name')
export SPACE_NAME

echo "Setting up proxy in $APP_NAME on $SPACE_NAME"

# basic auth
if [ "$ENABLE_BASIC_AUTH" = "true" ]; then
    echo "Setting up basic authentication"
    HTPASSWD_CONTENT=$(vcap_get_service secrets .credentials.htpasswd_content)
    if [ "$HTPASSWD_CONTENT" != "null" ] && [ -n "$HTPASSWD_CONTENT" ]; then
        mkdir -p ./nginx-auth || true
        echo "$HTPASSWD_CONTENT" > ./nginx-auth/.htpasswd
        echo "Basic auth file created successfully at ./nginx-auth/.htpasswd"
    else
        echo "Warning: ENABLE_BASIC_AUTH is true but no secrets service found or htpasswd_content is empty"
    fi
fi

# sitemap config
# url constructed in nginx conf
# the jankiness and shame of this is immeasurable
S3_URL=$(vcap_get_service s3 .credentials.endpoint)
sed -i "s/s3_url_placeholder/${S3_URL}/" ./nginx-common.conf
S3_BUCKET=$(vcap_get_service s3 .credentials.bucket)
sed -i "s/s3_bucket_placeholder/${S3_BUCKET}/" ./nginx-common.conf
