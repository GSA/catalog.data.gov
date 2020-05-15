
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
  
  export PGPASSWORD=$CKAN_DB_PW

  while [ $len_api_key -le 10 ]; do
    local sql_command="psql -h $DB_HOST -U ckan $CKAN_DB -c 'select apikey from public.user where name=\"$CKAN_USER_ADMIN\";"
    
    run psql -h $DB_HOST -U ckan $CKAN_DB -c "select apikey from public.user where name='$CKAN_USER_ADMIN';"
    echo "Check API KEY: $sql_command" >&3
    echo " - $output" >&3

    local api_key=$(echo ${lines[2]} | xargs)

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

function test_create_org () {
  export PGPASSWORD=$CKAN_DB_PW
  
  run psql -h db -U ckan $CKAN_DB -c "select apikey from public.user where name='$CKAN_USER_ADMIN';"
  local api_key=$(echo ${lines[2]} | xargs)  # run fill $output with all response and $line with each response line
  
  local json_data=$( sed s/\$RNDCODE/$RNDCODE/g /tests/test-data/test-org-create-01.json )
  
  run curl -X POST \
    http://$HOST:$PORT/api/3/action/organization_create \
    -H "Authorization: $api_key" \
    -H "cache-control: no-cache" \
    -d "$json_data"

  local success=$(echo $output | grep -o '"success": true')

  if [ "$success" = '"success": true' ]; then
    return 0;
  else
    echo "Failed to create org. API KEY $api_key. RND $RNDCODE OUTPUT: $output" >&3
    return 1;
  fi
}

function test_create_dataset () {
  export PGPASSWORD=$CKAN_DB_PW
  
  run psql -h db -U ckan $CKAN_DB -c "select apikey from public.user where name='$CKAN_USER_ADMIN';"
  local api_key=$(echo ${lines[2]} | xargs)  # run fill $output with all response and $line with each response line
  echo "Create dataset API KEY = $api_key" >&3
  
  local json_data=$( sed s/\$RNDCODE/$RNDCODE/g /tests/test-data/test-package-create-01.json )
  
  run curl -X POST \
    http://$HOST:$PORT/api/3/action/package_create \
    -H "Authorization: $api_key" \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -d "$json_data"

  local success=$(echo $output | grep -o '"success": true')

  if [ "$success" = '"success": true' ]; then
    return 0;
  else
    echo "Failed to create dataset. API KEY $api_key. RND: $RNDCODE OUTPUT: $output" >&3
    return 1;
  fi
}

function test_read_dataset () {
  
  local test_url="http://$HOST:$PORT/api/3/action/package_show?id=test-dataset-$RNDCODE"
  run curl --fail --location --request GET $test_url --cookie ./cookie-jar
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

# to create (just once) random org and datasets
if [ -z $RNDCODE ]; then
    export RNDCODE=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
fi
