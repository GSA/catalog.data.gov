#!/bin/bash

# Custom script to do rolling restart...

# Input any app name
app_to_restart=$1

# If there is more than one instance of 'instances', the app is already restarting
if [[ $(cf app $app_to_restart | grep '^instances:' | wc -l) > 1 ]]; then
  echo "Deployment or Restart in progress... not doing anything"
  exit 0
fi

instances=$(cf app $app_to_restart | grep '^instances:' | sed 's/.*\///')

for (( i=1; i<=$instances; i++ ))
do
  cf restart-app-instance $app_to_restart $((i-1))
  # sleep 90
done;
