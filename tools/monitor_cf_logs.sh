#!/bin/bash

# Custom script to look at logs from run task...

# Input any app name, any task name and any log key
app_to_monitor=$1
task_to_monitor=$2
logs_to_print=$3

cf logs "$app_to_monitor" | grep "\[APP/TASK/$task_to_monitor/0\]" | grep "\[ckanext.$logs_to_print\]" &
BACKGROUND_PID=$!

while ! ( cf logs --recent "$app_to_monitor" | grep "\[APP/TASK/$task_to_monitor/0\] OUT Exit status" )
do 
  sleep 2
done

if cf logs --recent "$app_to_monitor" | grep "\[APP/TASK/$task_to_monitor/0\] OUT Exit status 0"
then
  exit_code=0
else
  exit_code=1
fi

kill -9 $BACKGROUND_PID
kill -9 $((BACKGROUND_PID-1))
kill -9 $((BACKGROUND_PID-2))

exit $exit_code
