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
  local api_key
  api_key=$(db -c "select apikey from public.user where name='$CKAN_SYSADMIN_NAME';")

  # Template the dataset JSON payload with a random code to provide uniqueness
  # to the dataset.
  local json_data=$( sed s/\$RNDCODE/$RNDCODE/g /tests/test-data/test-org-create-01.json )
  run curl --silent -X POST \
    http://$HOST:$PORT/api/3/action/organization_create \
    -H "Authorization: $api_key" \
    -H "cache-control: no-cache" \
    -d "$json_data"

  [ "$status" = 0 ]
  assert_json .success true
}

@test "Given an organization, a waf-collection harvest source is created successfully from form" {
  # create a waf-collection harvest source
  # asserts ckan/patches/ckan/unflattern_indexerror.patch is applied
  # require the organization created in previous test

  local api_key json_data existing_org
  api_key=$(db -c "select apikey from public.user where name='$CKAN_SYSADMIN_NAME';")
  json_data=$(sed s/\$RNDCODE/$RNDCODE/g /tests/test-data/waf-collection-source.json)

  run curl --silent -X POST \
    http://$HOST:$PORT/api/3/action/package_create \
    -H "Authorization: $api_key" \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/x-www-form-urlencoded' \
    -d "$json_data"

  [ "$status" = 0 ]
  assert_json .success true
}



@test "User can create dataset" {
  local api_key json_data

  api_key=$(db -c "select apikey from public.user where name='$CKAN_SYSADMIN_NAME';")
  json_data=$(sed s/\$RNDCODE/$RNDCODE/g /tests/test-data/test-package-create-01.json)

  run curl --silent -X POST \
    http://$HOST:$PORT/api/3/action/package_create \
    -H "Authorization: $api_key" \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -d "$json_data"

  [ "$status" = 0 ]
  assert_json .success true
}

@test "data is accessible for user" {
  test_read_dataset
}

@test "data is inaccessible to public" {
  run curl --fail --location --request GET "http://$HOST:$PORT/api/3/action/package_show?id=test-dataset-$RNDCODE"
  [ "$status" -eq 22 ]
}
