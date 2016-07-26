#!/bin/bash

#  check VM status
#

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# determine corectl path
corectl_path=$(which corectl)
if [ "$corectl_path" == "" ]; then
  corectl_path=/usr/local/sbin/corectl
fi

# check VM status
status=$($corectl_path ps 2>&1 | grep "[k]8solo-01")

if [ "$status" = "" ]; then
    echo -n "VM is stopped"
else
    echo -n "VM is running"
fi
