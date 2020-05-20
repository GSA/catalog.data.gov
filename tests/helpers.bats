#!/usr/bin/env bats
#
# Test the test helpers in test_helper.bash
#

load test_helper

@test "when I log with arguments then the arguments are printed to stderr" {
  output=$(log "a" "b" 2>&1 > /dev/null)
  assert_output "a b"
}

@test "when I log with stdin then stdin is printed to stderr" {
  output=$(echo a b | log 2>&1 > /dev/null)
  assert_output "a b"
}
