#!/bin/bash

#  update OS X clients
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# get VM IP
vm_ip=$(cat ~/kube-solo/.env/ip_address)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# copy files to ~/kube-solo/bin
cp -f "${res_folder}"/files/* ~/kube-solo/bin
# copy xhyve to bin folder
cp -f "${res_folder}"/bin/xhyve ~/kube-solo/bin
chmod 755 ~/kube-solo/bin/*

# download latest version of fleetctl client
download_osx_clients
#

echo " "
echo "Update has finished !!!"
pause 'Press [Enter] key to continue...'

