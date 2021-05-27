#!/usr/bin/env batsPI

load globals
load test_helper

function setup_file {
  dataset_name=test-package-create-02-public
  organization_name=test-org-create-01

  api_post_call "api/3/action/organization_create" "${organization_name}"
  api_post_call "api/3/action/package_create" "${dataset_name}"

  api_get_call "api/3/action/package_show?id=${dataset_name}"
  dataset_id=$(echo $output | jq --raw-output '.result.id')
}

function teardown_file {
  # Delete objects
  api_delete_call package delete "${dataset_name}"
  api_delete_call organization delete "${organization_name}"

  # Purge objects
  api_delete_call package purge "${dataset_name}"
  api_delete_call organization purge "${organization_name}"
}

@test "DCAT extension is loaded" {
  test_extension_loaded dcat
}

@test "Dataset page links to DCAT RDF feed" {
  test_content "dataset/${dataset_name}" "<link rel=\"alternate\" type=\"application/rdf+xml\" href=\"*/dataset/${dataset_id}.rdf\"/>"
}

@test "RDF (DCAT) endpoint is working" {
  test_content dataset/test-dataset-public-$RNDCODE.rdf dcat:Dataset
}
