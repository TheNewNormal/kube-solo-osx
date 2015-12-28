#!/bin/bash

#  halt.command

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# get password for sudo
my_password=$(security find-generic-password -wa kube-solo-app)
# reset sudo
sudo -k
# enable sudo
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1

# send halt to VM
#sudo "${res_folder}"/bin/corectl ssh k8solo-01 sudo halt
sudo "${res_folder}"/bin/corectl halt k8solo-01
