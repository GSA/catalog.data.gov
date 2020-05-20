#!/usr/bin/env bats
#
# Test the test helpers in test_helper.bash
#

load test_helper

@test 'when log called with arguments then the arguments are printed to stderr' {
  output=$(log "a" "b" 2>&1 > /dev/null)
  assert_output "a b"
}

@test 'when log called with stdin then stdin is printed to stderr' {
  output=$(echo a b | log 2>&1 > /dev/null)
  assert_output "a b"
}

@test 'given json with match when assert_json called then success' {
  run echo '{"name": "fred"}'
  run assert_json .name fred

  test "$status" -eq 0
  test "${#lines[@]}" -eq 0
}

@test 'given json without match when assert_json called then failure' {
  run echo '{"name": "fred"}'
  run assert_json .name bob

  expected=$(cat <<EOF
selector : .name
actual   : fred
expected : bob
output   : {"name": "fred"}
EOF
)

  test "$status" -eq 1
  test "$output" == "$expected"
}

@test 'given invalid json when assert_json called then failure' {
  run echo not json
  run assert_json .name fred

  log "$output"
  # Watch out for the trailing space in expected output
  expected=$(cat <<EOF
parse error: Invalid literal at line 1, column 4
selector : .name
actual   : 
expected : fred
output   : not json
EOF
)

  test "$status" -eq 1
  test "$output" == "$expected"
}
