#!/bin/bash

# Custom script to look at logs from run task...

# Input any app name, any task name and any log key
app_to_monitor=$1
task_to_monitor=$2
logs_to_print=$3
task_id=$4

cf logs "$app_to_monitor" | grep "\[APP/TASK/$task_to_monitor/0\]" | grep "$logs_to_print\]" &
BACKGROUND_PID=$!

# Figure out which page the task is on
results_per_page=50
task_metadata=$(cf curl "/v3/apps/$(cf app $app_to_monitor --guid)/tasks?per_page=$results_per_page" | jq '.pagination')
task_total=$(echo $task_metadata | jq '.pagination.total_results')
last_page=$(echo $task_metadata | jq '.pagination.total_pages')

task_last_page=$((task_total%results_per_page))
task_page=$((task_id%results_per_page))

while true
do
  if [[ $task_page < $task_last_page ]]; then
    # Task is on last page
    task_info=$(cf curl \
      "/v3/apps/$(cf app $app_to_monitor --guid)/tasks?page=$last_page&per_page=$results_per_page" | \
      jq ".resources[] | select(.sequence_id==$task_id) | .state")
  else
    # Task is on second to last page
    task_info=$(cf curl \
      "/v3/apps/$(cf app $app_to_monitor --guid)/tasks?page=$((last_page-1))&per_page=$results_per_page" | \
      jq ".resources[] | select(.sequence_id==$task_id) | .state")
  fi

  if [[ "$task_info" = "SUCCEEDED" ]]; then
    exit_code=0
    break
  fi
  if [[ "$task_info" = "FAILED" ]]; then
    exit_code=1
    break
  fi
  sleep 2
done


kill -9 $BACKGROUND_PID
kill -9 $((BACKGROUND_PID-1))
kill -9 $((BACKGROUND_PID-2))

exit $exit_code
