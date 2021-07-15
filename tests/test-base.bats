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

@test "Given an organization, Demo CKAN harvest source is created and harvested successfully" {
  # create a ckan harvest source

  api_post_call "api/3/action/organization_create" "test-org-create-01"
  local org_id=$(echo "$output" | jq --raw-output '.result.id')

  # check the form
  api_get_call "harvest/new"
  
  local source_name="demo-ckan"
  local source_title="Demo CKAN"
  local source_url="https://demo.ckan.org"
  
  run curl --silent \
    --data-urlencode "name=$source_name" \
    --data-urlencode "url=$source_url" \
    --data-urlencode "source_type=ckan" \
    --data-urlencode "title=$source_title" \
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
  api_get_call "api/3/action/harvest_source_show?id=$source_name"
  
  if [ "$status" -ne 0 ]
  then
    echo "Error $status reading harvest source at $url" >&3
    return 1
  fi
  assert_json .success true

  local source_id=$(echo "$output" | jq --raw-output '.result.id')

  # start a harvesting job
  run curl --silent \
    -X POST http://$HOST:$PORT/harvest/refresh/$source_id \
    -H "Authorization: $api_key" \
    -H 'content-type: application/x-www-form-urlencoded' \
    --cookie $BATS_TMPDIR/cookie-jar

  if [ "$status" -ne 0 ]
  then
    echo "Error starting harvest job: $output" >&3
    return 1
  fi

  # check the job status
  api_get_call "api/3/action/harvest_source_show?id=$source_name"

  if [ "$status" -ne 0 ]
  then
    echo "Error $status reading harvest source at $url" >&3
    return 1
  fi
  assert_json .success true

  echo "# Waiting for harvest job to complete" >&3
  local retries=5
  local count_harvested_datasets=0

  while [ $count_harvested_datasets -lt 1 ]; do
    api_get_call "api/3/action/harvest_source_show?id=$source_name"

    if [ "$status" = 0 ]; then
      count_harvested_datasets=$(echo "$output" | jq --raw-output '.result.status.total_datasets')
    fi

    if [ "$retries" -le 0 ]; then
      return 1
    fi

    retries=$(( $retries - 1 ))
    sleep 3
  done

  echo "# Harvested $count_harvested_datasets datasets from $source_name" >&3


  # clear the harvest source
  run curl --silent \
    -X POST http://$HOST:$PORT/harvest/clear/$source_id \
    -H "Authorization: $api_key" \
    -H 'content-type: application/x-www-form-urlencoded' \
    --cookie $BATS_TMPDIR/cookie-jar

  # delete harvest source
  api_delete_call "harvest_source" "delete" "$source_name"

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
