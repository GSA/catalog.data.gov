#!/bin/bash

# Custom script to look at logs from run task...

# Input any app name
app_to_monitor=$1
task_to_monitor=$2

cf logs "$app_to_monitor" | grep "\[APP/TASK/$task_to_monitor/0\]" &
BACKGROUND_PID=$!

while ! ( cf logs --recent "$app_to_monitor" | grep "\[APP/TASK/$task_to_monitor/0\] OUT Exit status 0" )
do 
  sleep 2
done

kill -9 $BACKGROUND_PID
kill -9 $((BACKGROUND_PID-1))
