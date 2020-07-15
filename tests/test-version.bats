#!/usr/bin/env batsPI

@test "CKAN 2.8.5 still not ready" {
  # CKAN 2.8.5 will backport what we patch with "unflattern_indexerror.patch"
  # Once CKAN 2.8.5 is ready we need to remove the patch and update 
  local url='https://github.com/ckan/ckan/tree/ckan-2.8.5'
  output=$(curl -s -o /dev/null -I -w "%{http_code}" $url)
  
  [ "$output" = "404" ]
}