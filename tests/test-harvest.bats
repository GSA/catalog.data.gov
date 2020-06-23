#!/usr/bin/env batsPI

load globals
load test_helper

@test "datagov_harvest extension is loaded" {
  test_extension_loaded datagov_harvest
}

@test "Harvest URL exists" {
  test_url harvest
}