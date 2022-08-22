#!/bin/bash

# Custom script to ensure gather process is safe to restart
# Based on https://github.com/GSA/data.gov/issues/3796

###################
# Utility Functions
# Get the number of lines in the log (int)
log_count () { cf logs --recent catalog-gather | wc -l; }

# Get the time of the last line in the log (int)
current_time=$(date --utc +%s)
log_last_time () {
  date --utc --date="$(cf logs --recent catalog-gather | tail -n 1 | awk '{split($0,time," "); print time[1]}')" +%s
}

# Get CPU reading
cpu_integer () { cf app catalog-gather | tail -n 1 | awk '{ split($4,cpu,"."); print cpu[1]}'; }
cpu_decimal () { cf app catalog-gather | tail -n 1 | awk '{ split($4,cpu,"."); split(cpu[2],dec,"%"); print dec[1]}'; }

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
# if CPU usage is less then 1%, it's okay to restart
if [[ $((`cpu_integer` < 1)) ]]; then
  cf restart catalog-gather
fi
