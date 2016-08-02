#!/bin/bash

#  check VM status
#

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# check VM status
status=$(~/bin/corectl ps 2>&1 | grep "[k]8solo-01")

if [ "$status" = "" ]; then
    echo -n "VM is stopped"
else
    echo -n "VM is running"
fi
