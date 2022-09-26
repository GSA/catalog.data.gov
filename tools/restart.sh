#!/bin/bash

# Custom script to do rolling restart...

# Input any app name
app_to_restart=$1

instances=$(cf app $app_to_restart | grep '^instances:' | sed 's/.*\///')

# for i in {1..$((instances))}
for (( i=1; i<=$instances; i++ ))
do
  cf restart-app-instance $app_to_restart $((i-1))
  sleep 90
done;
