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

echo "Setting up proxy in $APP_NAME on $SPACE_NAME"

# sitemap config
# url constructed in nginx conf
# the jankiness and shame of this is immeasurable
S3_URL=$(vcap_get_service s3 .credentials.endpoint)
sed -i "s/s3_url_placeholder/${S3_URL}/" ./nginx-common.conf
S3_BUCKET=$(vcap_get_service s3 .credentials.bucket)
sed -i "s/s3_bucket_placeholder/${S3_BUCKET}/" ./nginx-common.conf
