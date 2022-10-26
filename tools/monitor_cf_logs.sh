#!/bin/bash

# Custom script to look at logs from run task...

# Input any app name, any task name and any log key
# log key helps to prevent printing sensitive info such as redis password
app_to_monitor=$1
task_to_monitor=$2
logs_to_print=$3

while read line ; do
  echo $line | grep --line-buffered "$logs_to_print\]"
  if echo $line | grep "OUT Exit status 0"; then
    exit 0
  elif echo $line | grep "OUT Exit status"; then
    exit 1
  fi
done < <(cf logs "$app_to_monitor" | grep  --line-buffered "\[APP/TASK/$task_to_monitor/0\]")
