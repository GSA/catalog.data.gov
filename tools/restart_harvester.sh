#!/bin/bash

# Custom script to ensure harvester processes are safe to restart
# Based on
#  - https://github.com/GSA/data.gov/issues/3796
#  - https://github.com/GSA/data.gov/issues/3962

# Input either catalog-gather or catalog-fetch
app_to_restart=$1

# Install jq
sudo apt install -y jq

# Check if deployment is happening, if so ignore
guid=$(cf app "$1" --guid)
running=$(cf curl "/v3/deployments?status_values=ACTIVE" | jq --arg guid "$guid" ".resources[] | select(.relationships.app.data.guid == \$guid ) | .relationships.app.data.guid")
if [ $running != "" ]; then
        echo "Deployment in progress for $1, not doing anything"
        exit 0
fi

###################
# Utility Functions
# Get the number of lines in the log (int)
log_count () { cf logs --recent $app_to_restart | wc -l; }

# Get the time of the last line in the log (int)
current_time=$(date --utc +%s)
log_last_time () {
  date --utc --date="$(cf logs --recent $app_to_restart | tail -n 1 | awk '{split($0,time," "); print time[1]}')" +%s
}

# Restart if CPU usage is < 1
cpu_restart () {
  instances=$(cf app $app_to_restart | grep '^instances:' | sed 's/.*\///')
  i=0
  cf app $app_to_restart | tail -n $instances | awk '{ split($4,cpu,"."); print cpu[1]}' | while read -r cpu ; do
    if [[ $cpu < 1 ]]; then
      cf restart-app-instance $app_to_restart $i
    fi
    i=$(($i + 1))
  done;
}

############
# Main Logic
# Check the age of the last log
# If there are only two lines, there are no logs
if [[ $((`log_count` > 2)) == '1' ]]; then
  # if the timestamp is younger than 15 mins from start of script
  if [[ $((current_time - `log_last_time` < 900)) == '1' ]]; then
    echo "Logs are too new!  Not going to restart"
    exit 0
  fi
fi

# if CPU status shows it is not busy, we do the restart
cpu_restart
