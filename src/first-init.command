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
echo "Setting up Kubernetes Solo on OS X"

# add ssh key to custom.conf
echo " "
echo "Reading ssh key from $HOME/.ssh/id_rsa.pub  "
file="$HOME/.ssh/id_rsa.pub"

while [ ! -f "$file" ]
do
    echo " "
    echo "$file not found."
    echo "please run 'ssh-keygen -t rsa' before you continue !!!"
    pause 'Press [Enter] key to continue...'
done

echo " "
echo "$file found, updating custom.conf..."
echo "SSHKEY='$(cat $HOME/.ssh/id_rsa.pub)'" >> ~/kube-solo/custom.conf
#

# save user's password to Keychain
save_password
#

# Set release channel
release_channel

# now let's fetch ISO file
echo " "
echo "Fetching lastest CoreOS $channel channel ISO ..."
echo " "
cd ~/kube-solo/
"${res_folder}"/bin/coreos-xhyve-fetch -f custom.conf
echo " "
#

# create ROOT disk
create_root_disk

echo " "
# Start VM
echo "Starting VM ..."
"${res_folder}"/bin/dtach -n ~/kube-solo/.env/.console -z "${res_folder}"/start_VM.command
#

# wait till VM is booted up
echo "You can connect to VM console from menu 'Attach to VM's console' "
echo "When you done with console just close it's window/tab with CMD+W "
echo "Waiting for VM to boot up..."
spin='-\|/'
i=1
until [ -e ~/kube-solo/.env/.console ] >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#
sleep 3

# get VM IP
echo "Waiting for VM to be ready..."
spin='-\|/'
i=1
until cat ~/kube-solo/.env/ip_address | grep 192.168.64 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
vm_ip=$(cat ~/kube-solo/.env/ip_address)
#
# waiting for VM's response to ping
spin='-\|/'
i=1
while ! ping -c1 $vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#

# install k8s files on to VM
install_k8s_files
#

# download latest version fleetctl client
download_osx_clients
#

# set fleetctl endpoint and install fleet units
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

# generate kubeconfig file
echo Generate kubeconfig file ...
"${res_folder}"/bin/gen_kubeconfig $vm_ip
#

# set kubernetes master
export KUBERNETES_MASTER=http://$vm_ip:8080
#
echo Waiting for Kubernetes cluster to be ready. This can take a few minutes...
spin='-\|/'
i=1
until ~/kube-solo/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
i=1
until ~/kube-solo/bin/kubectl get nodes | grep $vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
# attach label to the node
~/kube-solo/bin/kubectl label nodes $vm_ip node=worker1
#
install_k8s_add_ons "$vm_ip"
#
echo " "
echo "kubectl get nodes:"
~/kube-solo/bin/kubectl get nodes
echo " "
#
echo "Installation has finished, Kube Solo VM is up and running !!!"
echo " "
echo "Assigned static VM's IP: $vm_ip"
echo " "
echo "Enjoy Kube Solo on your Mac !!!"
echo " "
echo "Run from menu 'OS Shell' to open a terninal window with fleetctl, etcdctl and kubectl pre-set !!!"
echo " "
echo 'You can close this window/tab with CMD + W'
echo " "
sleep 9000

open -a iTerm.app "${res_folder}"/os_shell.command



