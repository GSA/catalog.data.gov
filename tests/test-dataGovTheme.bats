#!/usr/bin/env batsPI

load globals
load test_helper

@test "DataGovTheme is loaded" {
  test_extension_loaded datagovtheme
}

@test "DataGovTheme is in HTML" {
  test_read_text_in_url http://$HOST:$PORT "datagovtheme.css"
}
