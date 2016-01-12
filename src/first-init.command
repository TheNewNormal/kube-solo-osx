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

# add ssh key to *.toml files
sshkey

# add ssh key to Keychain
ssh-add -K ~/.ssh/id_rsa &>/dev/null

# save user's password to Keychain
save_password
#

# Set release channel
release_channel

# create Data disk
create_data_disk

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
# check id /Users/homefolder is mounted, if not mount it
"${res_folder}"/bin/corectl ssh k8solo-01 'source /etc/environment; if df -h | grep ${HOMEDIR}; then echo 0; else sudo systemctl restart ${HOMEDIR}; fi' > /dev/null 2>&1

# save VM's IP
"${res_folder}"/bin/corectl q -i k8solo-01 | tr -d "\n" > ~/kube-solo/.env/ip_address
# get VM IP
vm_ip=$("${res_folder}"/bin/corectl q -i k8solo-01)
#

# install k8s files on to VM
install_k8s_files
#

# download latest version of fleetctl and helm clients
download_osx_clients
#

# run helm for the first time
helm up
# add kube-charts repo
helm repo add kube-charts https://github.com/TheNewNormal/kube-charts
# Get the latest version of all Charts from repos
helm up

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

echo "Also you can install Deis PaaS (http://deis.io) v2 alpha version with 'install_deis' command ..."
echo " "

cd ~/kube-solo
# open bash shell
/bin/bash




