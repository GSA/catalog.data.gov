#!/bin/bash

# Custom script to look at logs from run task...

# Input any app name
app_to_monitor=$1
task_to_monitor=$2

function print_logs() {
  cf logs "$app_to_monitor" > grep "[APP/TASK/$task_to_monitor]"
}

print_logs &

while ! ( cf logs --recent "$app_to_monitor" | grep "[APP/TASK/$task_to_monitor] OUT Exit status 0" )
do 
  sleep 2
done

exit 0