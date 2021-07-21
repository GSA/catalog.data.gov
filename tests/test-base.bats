#!/usr/bin/env batsPI

load globals
load test_helper


@test "CKAN container is up" {
  wait_for_app
}

@test "/user/login is up" {
  test_url user/login
}

@test "Location search is working" {
  test_content api/3/action/location_search?q=california "California City"
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
