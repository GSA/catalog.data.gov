#!/usr/bin/env batsPI

@test "CKAN 2.8.6 still not ready" {
  # CKAN 2.8.6 will backport several commits we need.
  # Once CKAN 2.8.6 is ready we need to update our branch 
  local url='https://github.com/ckan/ckan/tree/ckan-2.8.7'
  output=$(curl -s -o /dev/null -I -w "%{http_code}" $url)
  
  [ "$output" = "404" ]
}