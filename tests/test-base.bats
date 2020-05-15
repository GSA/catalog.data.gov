#!/usr/bin/env batsPI

load globals
load test_helper


@test "CKAN container is up" {
  wait_for_app
}

@test "/user/login is up" {
  test_url user/login
}

@test "Test admin login" {
  local url="http://$HOST:$PORT/login_generic?came_from=/user/logged_in"
  
  run curl --silent --fail $url \
    --compressed \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Origin: http://$HOST:$PORT' \
    -H 'Referer: http://$HOST:$PORT/user/login' \
    --data 'login=ckan_admin&password=test1234' \
    --cookie-jar ./cookie-jar
  
  [ "$status" -ne 22 ]
}

@test "User can create org" {
  test_create_org
}

@test "User can create dataset" {
  test_create_dataset
}

@test "data is accessible for user" {
  test_read_dataset
}

@test "data is inaccessible to public" {
  run curl --fail --location --request GET "http://$HOST:$PORT/api/3/action/package_show?id=test-dataset-$RNDCODE"
  [ "$status" -eq 22 ]
}