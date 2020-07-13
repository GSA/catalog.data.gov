# Test helpers

load /bats/lib/bats-support/load.bash
load /bats/lib/bats-assert/load.bash


# assert_json <jq-selector> <expected>
#
# Uses jq on `$output` and asserts the value matched by jq-selector matches
# the expected value.
function assert_json () {
  local actual expected selector
  selector=$1
  expected=$2

  {
    actual=$(echo "$output" | jq --raw-output "$selector")
    [ "$actual" = "$expected" ]
  } || fail <<EOF
selector : $selector
actual   : $actual
expected : $expected
output   : $output
EOF
}

# db [psql-args]
#
# stdin: SQL
#
# Wrapper for psql (defaults to ckan DB) for better shell support. A SQL error
# will cause psql to error. Removes headers and column delimiters from the
# output format for better parsing of the query response.
function db () {
  PGPASSWORD=ckan psql --no-align --quiet --tuples-only --set ON_ERROR_STOP=1 --host db --user ckan "$@"
}

# log <msg>...
#
# stdin: msg
#
# Outputs message to stderr so that will be displayed by bats only when the
# test fails.
function log () {
  if (( $# > 0)); then
    # Print the arguments
    echo "$@" >&2
  else
    # Print stdin
    cat >&2
  fi
}

function wait_for_app () {
  # The app takes quite a while to startup (solr initialization and
  # migrations), close to a minute. Make sure to give it enough time before
  # starting the tests.
  
  echo "# Waiting for DB $DB_HOST:$DB_PORT" >&3
  local retries=10
  while ! nc -z -w 30 "$DB_HOST" "$DB_PORT" ; do
    if [ "$retries" -le 0 ]; then
      return 1
    fi

    retries=$(( $retries - 1 ))
    # incremental wait
    sleep_time=$(((9 - retries)*10))
    echo "# ... waiting $sleep_time" >&3
    sleep $sleep_time
  done

  echo "# Waiting for ADMIN USER DB" >&3
  retries=15
  local len_api_key=0
  
  while [ $len_api_key -le 10 ]; do
    run db -c "select apikey from public.user where name='$CKAN_SYSADMIN_NAME';"

    if [ "$status" = 0 ]; then
      api_key="$output"
    fi

    echo "# API KEY $api_key" >&3
    len_api_key=${#api_key} 
    # api_key could be "(0 rows)" or "xxxxxx-a-real-api-key"
    if [ "$retries" -le 0 ]; then
      return 1
    fi

    retries=$(( $retries - 1 ))
    # incremental wait
    sleep_time=$(((14 - retries)*10))
    echo "# ... waiting $sleep_time" >&3
    sleep $sleep_time
  done

  echo "# Waiting for CKAN $HOST:$PORT" >&3
  retries=10
  while ! nc -z -w 30 "$HOST" "$PORT" ; do
    if [ "$retries" -le 0 ]; then
      return 1
    fi

    retries=$(( $retries - 1 ))
    sleep 5
  done
}

function test_url () {
  local url="http://$HOST:$PORT/$1"
  run curl --silent --fail $url
  [ "$status" -ne 22 ]
}

function test_read_dataset () {
  
  local test_url="http://$HOST:$PORT/api/3/action/package_show?id=test-dataset-$RNDCODE"
  run curl --fail --location --request GET $test_url --cookie $BATS_TMPDIR/cookie-jar
  local dataset_success=$(echo $output | grep -o '"success": true')


  if [ "$dataset_success" = '"success": true' ]; then
    return 0;
  else
    echo "Failed to read dataset URL = $test_url" >&3
    return 1;
  fi
}

function test_extension_loaded() {
  # GET a URL and check for test
  
  local extension="\"$1\""  # we need the extension inside quotes to avoid error
  local url="http://$HOST:$PORT/api/3/action/status_show"

  run curl --silent --fail --location --request GET $url
  
  if [ "$status" -ne 22 ]; then

    local success=$(echo $output | grep -o $extension)
    
    if [ "$success" = $extension ]; then
      return 0;
    else
      echo "Extension $extension is not loaded [$success] : $output" >&3
      return 1;
    fi
  else
    echo "FAIL at $url" >&3
    return 1
  fi
}

function create_organization() {
  
  api_key=$(db -c "select apikey from public.user where name='$CKAN_SYSADMIN_NAME';")

  # Template the dataset JSON payload with a random code to provide uniqueness
  # to the dataset.
  if [ "$1" ]; then
    RNDCODE=$1
  fi
  json_data=$( sed s/\$RNDCODE/$RNDCODE/g /tests/test-data/test-org-create-01.json )
  run curl --silent -X POST \
    http://$HOST:$PORT/api/3/action/organization_create \
    -H "Authorization: $api_key" \
    -H "cache-control: no-cache" \
    --cookie $BATS_TMPDIR/cookie-jar \
    -d "$json_data"

  [ "$status" = 0 ]
  assert_json .success true

  created_organization="$output"
}

function api_post_call() {
  # CKAN API CALL
  # $1 URL
  # $2: json file name at /tests/test-data/ (without the .json extension)
  local api_key json_data 

  api_key=$(db -c "select apikey from public.user where name='$CKAN_SYSADMIN_NAME';")
  json_data=$(sed s/\$RNDCODE/$RNDCODE/g /tests/test-data/$2.json)
  
  run curl --silent -X POST \
    http://$HOST:$PORT/$1 \
    -H "Authorization: $api_key" \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -d "$json_data"

  [ "$status" = 0 ]
  
  # only expect JSON results for POST calls
  assert_json .success true
  
  api_results=$output 
}

function api_get_call() {
  # CKAN API CALL
  # $1 URL
  local api_key 

  api_key=$(db -c "select apikey from public.user where name='$CKAN_SYSADMIN_NAME';")
  
  run curl --silent \
    http://$HOST:$PORT/$1 \
    -H "Authorization: $api_key" \
    -H 'cache-control: no-cache' \
    
  [ "$status" = 0 ]
  
  api_results=$output 
}

function api_delete_call() {
  # CKAN API CALL to delete
  # $1 object to delete (organization | package)
  # $2 delete method (purge|delete)
  # $3: name or id

  local api_key 

  api_key=$(db -c "select apikey from public.user where name='$CKAN_SYSADMIN_NAME';")
  
  run curl --silent -X POST \
    http://$HOST:$PORT/api/3/action/$1_$2 \
    -H "Authorization: $api_key" \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -d '{"id": "'"$3"'"}'

  [ "$status" = 0 ]
  
  # only expect JSON results for POST calls
  assert_json .success true
  
  api_results=$output 
}

# to create (just once) random org and datasets
if [ -z $RNDCODE ]; then
    export RNDCODE=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
fi
