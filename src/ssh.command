#!/bin/bash

#  ssh.command
# run commands on VM via ssh
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# determine corectl path
corectl_path=$(which corectl)
if [ "$corectl_path" == "" ]; then
  corectl_path=/usr/local/sbin/corectl
fi

# ssh into VM
$corectl_path ssh k8solo-01
