#!/bin/bash

#  Reload VM
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# check if k8s files are on VM
if /usr/local/sbin/corectl ssh k8solo-01 '[ ! -f /opt/bin/kube-apiserver ]' &> /dev/null
then
    echo " "
    echo "Found unfinished installation, aborting VM's boot !!!"
    echo "Stopping VM ..."
    # send halt to VM
    /usr/local/sbin/corectl halt k8solo-01
    echo " "
    echo "Just do 'Up' via menu to boot the VM and the installation will continue ... "
    echo " "
    pause 'Press [Enter] key to continue...'
    exit 0
fi

### Stop VM
echo " "
echo "Stopping VM ..."
# send halt to VM
/usr/local/sbin/corectl halt k8solo-01

#
sleep 3

# check corectld server
check_corectld_server

# Start VM
start_vm

# set fleetctl endpoint
export FLEETCTL_ENDPOINT=http://$vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false

# wait till VM is ready
echo "  "
echo "Waiting for etcd service to be ready on VM..."
spin='-\|/'
i=1
until curl -o /dev/null http://$vm_ip:2379 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
#

sleep 2

#
echo " "
echo "fleetctl list-machines:"
fleetctl list-machines
echo " "

sleep 2

# deploy fleet units from ~/kube-solo/fleet
deploy_fleet_units
#

echo "CoreOS VM was reloaded !!!"
echo ""
pause 'Press [Enter] key to continue...'
