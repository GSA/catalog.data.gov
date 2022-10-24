#!/bin/bash
# Script to query recent tasks for apps.  It works with any app, but
# is designed to make apps with 1000s (or more) tasks have the same
# runtime as 10s of tasks

# $1 is the name of the app to get tasks for
guid=$(cf app $1 --guid)

# Get the last two pages
last_page=$(cf curl "/v3/apps/$guid/tasks?per_page=10" | jq -r '.pagination.total_pages')

cf curl "/v3/apps/$guid/tasks?per_page=10&page=$last_page" | jq -r '.resources[] | "\(.sequence_id) \(.name) \(.state) \(.command)"'
cf curl "/v3/apps/$guid/tasks?per_page=10&page=$((last_page-1))" | jq -r '.resources[] | "\(.sequence_id) \(.name) \(.state) \(.command)"'

# All available options
# guid, created_at, updated_at, sequence_id, name, command, state,
# memory_in_mb, disk_in_mb, log_rate_limit_in_bytes_per_second,
# result.failure_reason, failure_reason, relationships.app.data.guid,
# links, metadata
