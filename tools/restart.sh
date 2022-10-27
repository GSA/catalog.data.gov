#!/bin/bash

# Custom script to do rolling restart...

# Input any app name
app_to_restart=$1

# Check if deployment is happening, if so ignore
guid=$(cf app "$1" --guid)
running=$(cf curl "/v3/deployments?status_values=ACTIVE" | jq --arg guid "$guid" ".resources[] | select(.relationships.app.data.guid == \$guid ) | .relationships.app.data.guid")
if [ "$running" != "" ]; then
        echo "Deployment in progress for $1, not doing anything"
        exit 0
fi

# If there is more than one instance of 'instances', the app is already restarting
if [[ $(cf app "$app_to_restart" | grep -c '^instances:') -gt 1 ]]; then
  echo "Deployment or Restart in progress... not doing anything"
  exit 0
fi

instances=$(cf app "$app_to_restart" | grep '^instances:' | sed 's/.*\///')


if [[ $instances == 1 ]]; then
  cf restart "$app_to_restart" --strategy rolling
else
  for (( i=1; i<=instances; i++ ))
  do
    cf restart-app-instance "$app_to_restart" $((i-1))
    sleep 90
  done
fi
