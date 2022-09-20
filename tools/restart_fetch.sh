#!/bin/bash

# Custom script to ensure fetch process is safe to restart
# Based on https://github.com/GSA/data.gov/issues/3962

###################
# Utility Functions
# Get the number of lines in the log (int)
log_count () { cf logs --recent catalog-fetch | wc -l; }

# Get the time of the last line in the log (int)
current_time=$(date --utc +%s)
log_last_time () {
  date --utc --date="$(cf logs --recent catalog-fetch | tail -n 1 | awk '{split($0,time," "); print time[1]}')" +%s
}

# Get CPU status
cpu_status () {
  instances=$(cf app catalog-fetch | grep '^instances:' | sed 's/.*\///')
  cf app catalog-fetch | tail -n $instances | awk '{ split($4,cpu,"."); print cpu[1]}' | while read -r cpu ; do
    if [[ $cpu > 1 ]]; then
      echo "busy";
      break
    fi
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
    exit 1
  fi
fi

# if CPU status shows it is not busy, we do the restart
if [[ $(cpu_status) != "busy" ]]; then
  cf restart catalog-fetch
fi
