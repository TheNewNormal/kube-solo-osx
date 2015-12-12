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
echo "Setting up Kubernetes Solo Cluster on OS X"

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
echo "$file found, updating configuration files ..."
echo "   sshkey = '$(cat $HOME/.ssh/id_rsa.pub)'" >> ~/kube-solo/settings/k8solo-01.toml
echo "   sshkey = '$(cat $HOME/.ssh/id_rsa.pub)'" >> ~/kube-solo/settings/format-root.toml
#

##ssh-add ~/.ssh/id_rsa.pub &>/dev/null

# save user's password to Keychain
save_password
#

# Set release channel
release_channel

# create ROOT disk
create_root_disk

# get password for sudo
my_password=$(security find-generic-password -wa kube-solo-app)
# reset sudo
sudo -k > /dev/null 2>&1

# Start VM
cd ~/kube-solo
echo " "
echo "Starting VM ..."
echo " "
echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1
#
sudo "${res_folder}"/bin/corectl load settings/k8solo-01.toml

# get VM IP
#vm_ip=$(corectl ps -j | jq ".[] | select(.Name==\"k8solo-01\") | .PublicIP" | sed -e 's/"\(.*\)"/\1/')
vm_ip=$(cat ~/kube-solo/.env/ip_address);
#

# install k8s files on to VM
install_k8s_files
#

# download latest version fleetctl client
download_osx_clients
#

# set etcd endpoint
export ETCDCTL_PEERS=http://$vm_ip:2379

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
echo Waiting for Kubernetes cluster to be ready. This can take a few minutes...
spin='-\|/'
i=1
until curl -o /dev/null http://$vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
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
echo "fleetctl list-machines:"
fleetctl list-machines
echo " "
echo "fleetctl list-units:"
fleetctl list-units
echo " "
echo "kubectl get nodes:"
~/kube-solo/bin/kubectl get nodes
echo " "
#
echo "Installation has finished, Kube Solo VM is up and running !!!"
echo " "
echo "Assigned static IP for VM: $vm_ip"
echo " "
echo "You can control this App via status bar icon... "
echo " "

cd ~/kube-solo
# open bash shell
/bin/bash




