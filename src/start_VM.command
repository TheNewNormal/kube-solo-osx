#!/bin/bash

# Start VM
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# Get UUID
UUID=$(cat ~/kube-solo/custom.conf | grep UUID= | head -1 | cut -f2 -d"=")

# Get password
my_password=$(security find-generic-password -wa kube-solo-app)

# Get mac address and save it
echo -e "$my_password\n" | sudo -S "${res_folder}"/bin/uuid2mac $UUID > ~/kube-solo/.env/mac_address

# Get VM's IP and save it to file
"${res_folder}"/bin/get_ip &

# Start webserver
cd ~/kube-solo/cloud-init
"${res_folder}"/bin/webserver start

# Start VM
#echo "Waiting for VM to boot up... "
cd ~/kube-solo
export XHYVE=~/kube-solo/bin/xhyve
"${res_folder}"/bin/coreos-xhyve-run -f custom.conf kube-solo

# Stop webserver
"${res_folder}"/bin/webserver stop
