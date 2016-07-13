#!/bin/bash

#  first-init.command
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

echo " "
echo "Setting up Kubernetes Solo Cluster on macOS"

# add ssh key to *.toml files
sshkey

# add ssh key to Keychain
if ! ssh-add -l | grep -q ssh/id_rsa; then
  ssh-add -K ~/.ssh/id_rsa &>/dev/null
fi

# Set release channel
release_channel

# set VM's RAM
change_vm_ram

# create Data disk
create_data_disk

# Start VM
start_vm

# get VM's IP
vm_ip=$(/usr/local/sbin/corectl q -i k8solo-01)

# check internet from VM
echo " "
echo "Checking internet availablity on VM..."
check_internet_from_vm

# install k8s files on to VM
install_k8s_files
#

# download latest version of fleetctl and helmc clients
download_osx_clients
#

# run helmc for the first time
helmc up

# set etcd endpoint
export ETCDCTL_PEERS=http://$vm_ip:2379
# wait till etcd service is ready
echo "--------"
echo " "
echo "Waiting for etcd service to be ready on VM..."
spin='-\|/'
i=1
until curl -o /dev/null http://$vm_ip:2379 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "


# set fleetctl endpoint and install fleet units
export FLEETCTL_TUNNEL=
export FLEETCTL_ENDPOINT=http://$vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
echo " "
echo "fleetctl list-machines:"
fleetctl list-machines
echo " "
#
deploy_fleet_units
#

sleep 2

# generate kubeconfig file
echo Generate kubeconfig file ...
"${res_folder}"/bin/gen_kubeconfig $vm_ip
#

# set kubernetes master
export KUBERNETES_MASTER=http://$vm_ip:8080
#
echo " "
echo "Waiting for Kubernetes cluster to be ready. This can take a few minutes..."
spin='-\|/'
i=1
until curl -o /dev/null http://$vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-solo/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
i=1
until ~/kube-solo/bin/kubectl get nodes | grep -w "k8solo-01" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
# attach label to the node
~/kube-solo/bin/kubectl label nodes k8solo-01 node=worker1
#
install_k8s_add_ons
#
echo "fleetctl list-machines:"
fleetctl list-machines
echo " "
echo "fleetctl list-units:"
fleetctl list-units
echo " "

#
echo "Installation has finished, Kube Solo VM is up and running !!!"
echo " "
echo "Assigned static IP for VM: $vm_ip"
echo " "
echo "You can control this App via status bar icon... "
echo " "

echo "Also you can install Deis Workflow (https://deis.com) with 'install_deis' command ..."
echo " "

echo "kubectl get nodes:"
~/kube-solo/bin/kubectl get nodes
echo " "

echo "kubectl cluster-info:"
~/kube-solo/bin/kubectl cluster-info
echo " "

cd ~/kube-solo
# open bash shell
/bin/bash




