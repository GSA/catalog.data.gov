#!/usr/bin/env batsPI

load globals
load test_helper

@test "Harvest extension is loaded" {
  test_extension_loaded harvest
}

@test "Harvest page exists" {
  local url="http://$HOST:$PORT/harvest"
  run curl --silent --fail $url
  [ "$status" -ne 22 ]
}