#!/usr/bin/env batsPI

load globals
load test_helper

@test "datajson_harvest extension is loaded" {
  test_extension_loaded datajson_harvest
}

@test "data.json harvest source is created and harvested successfully" {

  # create a data.json harvest source
  api_post_call "api/3/action/organization_create" "test-org-create-01"
  local org_id=$(echo "$output" | jq --raw-output '.result.id')

  local source_name="gsa-data-json"
  local source_title="GSA data.json"
  local source_url="http://nginx-harvest-source/data.json"

  run curl --silent \
    --data-urlencode "name=$source_name" \
    --data-urlencode "url=$source_url" \
    --data-urlencode "source_type=datajson" \
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

  while [ $count_harvested_datasets -lt 5 ]; do
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

  # verify the count of datasets within a collection
  local parent_identifier="GSA-2015-09-11-01"
  local collection_id

  api_get_call "api/action/package_search?q=(identifier:$parent_identifier)"
  if [ "$status" = 0 ]; then
    collection_id=$(echo "$output" | jq --raw-output '.result.results[0].id')
  fi

  api_get_call "api/action/package_search?fq=(dataset_type:dataset+collection_package_id:$collection_id)"
  assert_json .result.count 2

  # clear the harvest source
  run curl --silent \
    -X POST http://$HOST:$PORT/harvest/clear/$source_id \
    -H "Authorization: $api_key" \
    -H 'content-type: application/x-www-form-urlencoded' \
    --cookie $BATS_TMPDIR/cookie-jar

  sleep 5

  # delete harvest source
  api_delete_call "harvest_source" "delete" "$source_name"

  # delete organization
  api_delete_call "organization" "purge" "test-organization-$RNDCODE"
}