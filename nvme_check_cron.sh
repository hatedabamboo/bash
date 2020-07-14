#!/bin/bash

# Written with passion by @hatedabamboo

# We check every 24 hours for threshold

TMPDIR='/var/tmp/nvmestat'
LOCK="$TMPDIR/.lock"
ALERT='/var/tmp/nvmealert'
LIST=($(ls /dev/nvme[0-9]n[0-9]))

THRESHOLD=1000000 # in MB

function die() {
  echo "[ERR] $*"
  exit 1
}

function get_nvme_list() {
  if [ ${#LIST[@]} == '0' ]; then
    die 'No NVMe devices found'
  else
    echo "Found ${#LIST[@]} devices"
  fi  
}

# get written data for each NVMe in MB
function get_written_data() { 
  if [ $# -ne 1 ]; then
    die 'Wrong amount of arguments for get_written_data'
  fi
  
  local device=$1  
  local blocks=''
  local megabytes=''
  local disk=''

  disk=$(echo "${device}" | awk -F'/' '{print $3}')
  blocks=$(/usr/sbin/smartctl -a $device | grep Written | awk '{print $4}' | tr -d ',')
  megabytes=$(echo "$blocks*512/1000/1000" | /usr/bin/bc)
  
  local tmpfile="$TMPDIR/$disk"

  echo "${megabytes}" > $tmpfile
}

function compare_data() {
  if [ $# -ne 1 ]; then
    die 'Wrong amount of arguments for compare_data'
  fi
  
  local device=$1
  local blocks=''
  local megabytes=''
  local disk=''
  local msg=''

  disk=$(echo "${device}" | awk -F'/' '{print $3}')
  blocks=$(/usr/sbin/smartctl -a $device | grep Written | awk '{print $4}' | tr -d ',')
  megabytes=$(echo "$blocks*512/1000/1000" | /usr/bin/bc)
  msg="Data writes on $disk greater then threshold<br>"

  if [ "$(echo "$megabytes - $(cat $TMPDIR/$disk)" | /usr/bin/bc)" -gt "$THRESHOLD" ]; then
    if [ -f $ALERT ]; then
      sed -i "s/$msg//" $ALERT
    fi
    printf "$msg" >> $ALERT
  else
    if [ -f $ALERT ]; then
      sed -i "s/$msg//" $ALERT
    fi
  fi
}

function get_temp() {
  if [ $# -ne 1 ]; then
    die 'Wrong amount of arguments for get_temp'
  fi
  
  local device=$1
  local disk=$(echo "${device}" | awk -F'/' '{print $3}')
  local temp=''
  local high_temp=''
  local msg=''

  temp=$(/usr/sbin/smartctl -A $device | grep Celsius | awk '{print $(NF-1)}')
  high_temp=$(/usr/sbin/smartctl -c $device | grep Warning | awk '{print $(NF-1)}')
  msg="$disk temperature level WARNING<br>"

  if [ $temp -ge $high_temp ]; then
    if [ -f $ALERT ]; then
      sed -i "s/$msg//" $ALERT
    fi
    printf "$msg" >> $ALERT
  else
    if [ -f $ALERT ]; then
      sed -i "s/$msg//" $ALERT
    fi
  fi
}

function get_health() {
  if [ $# -ne 1 ]; then
    die 'Wrong amount of arguments for get_health'
  fi

  [ -x /usr/sbin/nvme ] || ( apt-get update; apt-get install nvme-cli )
  
  local device=$1
  local disk=$(echo "${device}" | awk -F'/' '{print $3}')
  local msg=''

  msg="$disk health NOT OK<br>"

  if [ $(/usr/sbin/smartctl -i $device | grep -io intel) ]; then
    if [ "$(/usr/sbin/nvme intel id-ctrl $device | grep health | awk '{print $NF}')" != "healthy" ]; then
      if [ -f $ALERT ]; then
        sed -i "s/$msg//" $ALERT
      fi
      printf "$msg" >> $ALERT
    else
      if [ -f $ALERT ]; then
        sed -i "s/$msg//" $ALERT
      fi
    fi
  else
    echo "$disk not Intel, skip health check"
  fi
}

function data_processing() {
  if [ -f $LOCK ]; then
    if [ $(find $LOCK -mmin +1440) ]; then
      rm $LOCK
    else
      echo 'Lock found, avoid getting data'
      return
    fi
  fi

  touch $LOCK

  for device in ${LIST[@]}; do
    get_written_data $device
    compare_data $device
  done
}

function dependencies(){
  [ -x /usr/bin/bc ] || ( apt-get update; apt-get install bc )
  [ -x /usr/sbin/smartctl ] || ( apt-get update; apt-get install smartmontools )
  # [ -x /usr/bin/isdct ] || ( apt-get update; apt-get install isdct) # not in repo yet
}

[ -d $TMPDIR ] || mkdir -p $TMPDIR

dependencies
get_nvme_list
data_processing
for device in ${LIST[@]}; do
  get_temp $device
  get_health $device
done
