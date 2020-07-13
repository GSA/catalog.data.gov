#!/usr/bin/env batsPI

load globals
load test_helper


@test "CKAN container is up" {
  wait_for_app
}

@test "/user/login is up" {
  test_url user/login
}

@test "when the admin user logs in then the auth_tkt cookie is set" {
  local url="http://$HOST:$PORT/login_generic?came_from=/user/logged_in"

  # POST the login endpoint. We're not interested in the response body, only
  # the headers. We avoid `run` here because we need control of the
  # redirection.
  #
  # Side-effect: the `cookie-jar` is created with the admin session.
  output=$(curl --verbose --silent --location $url \
    --data "login=$CKAN_SYSADMIN_NAME" \
    --data "password=$CKAN_SYSADMIN_PASSWORD" \
    --cookie-jar $BATS_TMPDIR/cookie-jar 2>&1 > /dev/null)

  log "$output"
  echo "$output" | grep -qi '^< set-cookie:.*auth_tkt'
}

@test "when a user login fails then the auth_tkt cookie is not set" {
  local url="http://$HOST:$PORT/login_generic?came_from=/user/logged_in"

  # Post the login endpoint. We're not interested in the response body, but
  # Cookie header in order to assert our auth_tkt cookie is set.
  output=$(curl --verbose --silent --location $url \
    --data 'login=not_a_user' \
    --data 'password=badpassword' 2>&1 >/dev/null)

  log "$output"
  ! echo "$output" | grep -qi '^< set-cookie:.*auth_tkt'
}

@test "User can create org" {
  api_post_call "api/3/action/organization_create" "test-org-create-01"
  api_delete_call "organization" "purge" "test-organization-$RNDCODE"
}

@test "Given an organization, a waf-collection harvest source is created successfully from form" {
  # create a waf-collection harvest source
  # asserts ckan/patches/ckan/unflattern_indexerror.patch is applied
  # require the organization created in previous test

  api_post_call "api/3/action/organization_create" "test-org-create-01"
  local org_id=$(echo "$api_results" | jq --raw-output '.result.id')
  
  # check the form
  api_get_call "harvest/new"
  
  # check if the missing field it's OK
  if [[ "$api_results" != *"field-collection_metadata_url"* ]]
  then
    echo "Missing required field: collection_metadata_url" >&3
    return 1
  fi

  name="waf-collection-source-$RNDCODE"
  
  run curl --silent \
    --data-urlencode "name=$name" \
    --data-urlencode "url=http://test-$RNDCODE.com" \
    --data-urlencode "source_type=waf-collection" \
    --data-urlencode "title=WAF test $RNDCODE" \
    --data-urlencode "collection_metadata_url=http://coll-$RNDCODE.test.com" \
    --data-urlencode "frequency=MANUAL" \
    --data-urlencode "owner_org=$org_id" \
    --data-urlencode "private_datasets=False" \
    --data-urlencode "save=Save" \
    -X POST http://$HOST:$PORT/harvest/new \
    -H "Authorization: $api_key" \
    -H 'content-type: application/x-www-form-urlencoded' \
    --cookie $BATS_TMPDIR/cookie-jar
  
  if [ "$status" -ne 0 ]
  then
    echo "Error creating harvest source: $output" >&3
    return 1
  fi
  
  # check the source we created exists
  api_get_call "api/3/action/harvest_source_show?id=waf-collection-source-$RNDCODE"
  
  if [ "$status" -ne 0 ]
  then
    echo "Error $status reading harvest source at $url" >&3
    return 1
  fi
  assert_json .success true

  # delete harvest source
  api_delete_call "harvest_source" "delete" "waf-collection-source-$RNDCODE"

  # delete organization
  api_delete_call "organization" "purge" "test-organization-$RNDCODE"
}

@test "User can create dataset" {
  api_post_call "api/3/action/organization_create" "test-org-create-01"
  api_post_call "api/3/action/package_create" "test-package-create-01"
  api_delete_call "package" "delete" "test-dataset-$RNDCODE"
  api_delete_call "organization" "purge" "test-organization-$RNDCODE"
}

@test "data is accessible for user" {
  test_read_dataset
}

@test "data is inaccessible to public" {
  run curl --fail --location --request GET "http://$HOST:$PORT/api/3/action/package_show?id=test-dataset-$RNDCODE"
  [ "$status" -eq 22 ]
}
