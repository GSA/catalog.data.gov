#!/usr/bin/env bats

load test_helper

HOST="ckan"
PORT="5000"
CKAN_DB="ckan"
CKAN_DB_PW="ckan"
CKAN_USER_ADMIN="ckan_admin"
DB_HOST='db'
DB_PORT='5432'

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
    sleep 5
  done

  echo "# Waiting for ADMIN USER DB" >&3
  retries=10
  local len_api_key=0
  
  export PGPASSWORD=$CKAN_DB_PW

  while [ $len_api_key -le 10 ]; do
    run psql -h db -U ckan $CKAN_DB -c "select apikey from public.user where name='$CKAN_USER_ADMIN';"
    local api_key=$(echo ${lines[2]} | xargs)
    echo "# API KEY $api_key" >&3
    len_api_key=${#api_key} 
    # api_key could be "(0 rows)" or "xxxxxx-a-real-api-key"
    if [ "$retries" -le 0 ]; then
      return 1
    fi

    retries=$(( $retries - 1 ))
    sleep 10
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

function test_view_login () {
  local url="http://$HOST:$PORT/user/login"
  # echo "#   - Testing view login at $url" >&3
  run curl --silent --fail $url
  [ "$status" -ne 22 ]
}

function test_login () {

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

@test "CKAN container is up" {
  wait_for_app
}

@test "/user/login is up" {
  test_view_login
}

@test "Test admin login" {
  test_login
}
