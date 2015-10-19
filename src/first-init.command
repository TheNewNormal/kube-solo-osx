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
echo "Setting up CoreOS VM on OS X"

# add ssh key to custom.conf
echo " "
echo "Reading ssh key from $HOME/.ssh/id_rsa.pub  "
file="$HOME/.ssh/id_rsa.pub"
if [ -f "$file" ]
then
    echo "$file found, updating custom.conf..."
    echo "SSHKEY='$(cat $HOME/.ssh/id_rsa.pub)'" >> ~/kube-solo/custom.conf
else
    echo "$file not found."
    echo "please run 'ssh-keygen -t rsa' before you continue !!!"
    pause 'Press [Enter] key to continue...'
    echo "SSHKEY="$(cat $HOME/.ssh/id_rsa.pub)"" >> ~/kube-solo/custom.conf
fi
#

# save user password to file
echo "  "
echo "Your Mac user password will be saved to '~/kube-solo/.env/password' "
echo "and later one used for 'sudo' commnand to start VM !!!"
echo "Please type your Mac user's password followed by [ENTER]:"
read -s password
echo -n ${password} | base64 > ~/kube-solo/.env/password
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
i=0
until [ -e ~/kube-solo/.env/.console ] >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#
sleep 3

# get VM IP
echo "Waiting for VM to be ready..."
spin='-\|/'
i=0
until cat ~/kube-solo/.env/ip_address | grep 192.168.64 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
vm_ip=$(cat ~/kube-solo/.env/ip_address)
#
# waiting for VM's response to ping
spin='-\|/'
i=0
while ! ping -c1 $vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#

echo " "
# download latest versions of etcdctl, fleetctl and docker clients
download_osx_clients
#

# set fleetctl endpoint and install fleet units
export FLEETCTL_ENDPOINT=http://$vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
echo "fleetctl list-machines:"
fleetctl list-machines
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
pause 'Press [Enter] key to continue...'



