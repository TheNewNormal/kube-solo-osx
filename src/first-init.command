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
echo " "
start_vm

# get VM's IP
vm_ip=$(~/bin/corectl q -i k8solo-01)

# check internet from VM
echo " "
echo "Checking internet availablity on VM..."
check_internet_from_vm

# download latest version of deis and helm clients
###download_osx_clients
#

echo " "
# install k8s files on to VM
install_k8s_files
#

# Set the shell environment variables
# set etcd endpoint
export ETCDCTL_PEERS=http://$vm_ip:2379
# set kubernetes master endpoint
export KUBERNETES_MASTER=http://$vm_ip:8080

# generate kubeconfig file
echo " "
echo "Generating kubeconfig file ..."
"${res_folder}"/bin/gen_kubeconfig $vm_ip
#

# set kubernetes cluster config file path for Helm
export KUBECONFIG=~/kube-solo/kube/kubeconfig
export HELM_HOST=$vm_ip:32767

#
echo " "
echo "Waiting for etcd service to be ready on VM..."
sleep 3
spin='-\|/'
i=1
until curl -o /dev/null http://$vm_ip:2379 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo "..."

#
download_docker_client

# wait for Kubernetes cluster readiness
echo " "
echo "Waiting for Kubernetes cluster to be ready. This can take a bit..."
spin='-\|/'
i=1
until curl -o /dev/null http://$vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-solo/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
echo "..."
echo " "
echo "Waiting for Kubernetes node to be ready. This can take a bit..."
i=1
until ~/kube-solo/bin/kubectl get nodes | grep -w "k8solo-01" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo "..."
echo " "

# attach label to the node
~/kube-solo/bin/kubectl label nodes k8solo-01 node=worker1
#
install_k8s_add_ons

# download latest version of deis, helmc and helm clients
# install Helm Tiller
download_osx_clients

# docker daemon
export DOCKER_HOST=tcp://$vm_ip:2375
export DOCKER_TLS_VERIFY=
export DOCKER_CERT_PATH=

#
echo " "
echo "Installation has finished, Kube Solo VM is up and running !!!"
echo " "
echo "Assigned static IP to VM/node: $vm_ip"
echo " "
echo "You can control this App via status bar icon... "
echo "--------"

# remove unfinished_setup file if there is such one
rm -f ~/kube-solo/logs/unfinished_setup > /dev/null 2>&1

#
echo "kubectl cluster-info:"
~/kube-solo/bin/kubectl cluster-info
echo " "
echo "Cluster version:"
CLIENT_INSTALLED_VERSION=$(~/kube-solo/bin/kubectl version | grep "Client Version:" | awk '{print $5}' | awk -v FS='(:"|",)' '{print $2}')
SERVER_INSTALLED_VERSION=$(~/kube-solo/bin/kubectl version | grep "Server Version:" | awk '{print $5}' | awk -v FS='(:"|",)' '{print $2}')
echo "Client version: $CLIENT_INSTALLED_VERSION"
echo "Server version: $SERVER_INSTALLED_VERSION"
#
echo " "
echo "kubectl get nodes:"
~/kube-solo/bin/kubectl get nodes
#
echo " "
echo "Also you can install Deis Workflow PaaS (https://deis.com) with 'install_deis' command ..."
echo " "

cd ~/kube-solo

# open user's preferred shell
if [[ ! -z "$SHELL" ]]; then
    $SHELL
else
    /bin/bash
fi


