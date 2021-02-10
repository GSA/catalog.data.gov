#!/usr/bin/env batsPI

load globals
load test_helper

@test "DCAT extension is loaded" {
  test_extension_loaded dcat
}

@test "RDF endpoin is working" {
  api_post_call "api/3/action/organization_create" "test-org-create-01"
  api_post_call "api/3/action/package_create" "test-package-create-02-public"
  test_content dataset/test-dataset-public-$RNDCODE.rdf dcat:Dataset
}
