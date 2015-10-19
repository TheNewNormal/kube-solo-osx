#!/bin/bash

#  check VM status
#

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

status=$(ps aux | grep "[k]ube-solo/bin/xhyve" | awk '{print $2}')

if [ "$status" = "" ]; then
    echo -n "VM is stopped"
else
    echo -n "VM is running"
fi
