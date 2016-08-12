#!/bin/bash

# up.command
#

# clean up old version setup files
rm -rf ~/kube-solo/fleet > /dev/null 2>&1

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# check if offline setting is present in settings file
check_iso_offline_setting

# check corectld server
check_corectld_server

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# check if iTerm.app exists
App="/Applications/iTerm.app"
if [ ! -d "$App" ]
then
    unzip "${res_folder}"/files/iTerm2.zip -d /Applications/
fi

# create logs dir
mkdir ~/kube-solo/logs > /dev/null 2>&1

# copy bin files to ~/kube-solo/bin
rsync -r --verbose --exclude 'helmc' --exclude 'helm' --exclude 'gen_kubeconfig' "${res_folder}"/bin/* ~/kube-solo/bin/ > /dev/null 2>&1
chmod 755 ~/kube-solo/bin/*

# copy ksolo file to ~/bin
cp -f "${res_folder}"/bin/ksolo ~/bin

# add ssh key to Keychain
if ! ssh-add -l | grep -q ssh/id_rsa; then
  ssh-add -K ~/.ssh/id_rsa &>/dev/null
fi

# set variable to 0
new_vm=0

### run some checks
# check if root disk exists, if not create it
if [ ! -f "$HOME"/kube-solo/data.img ]; then
    echo " "
    echo "Starting k8solo-01 VM ..."
    echo " "
    echo "Data disk does not exist, it will be created now ..."
    create_data_disk
    new_vm=1
fi
#
# check if '~/kube-solo/logs/unfinished_setup' file exists
if [ -f "$HOME"/kube-solo/logs/unfinished_setup ]; then
    # found it, so installation will continue
    new_vm=1
fi
#
###

# Start VM
start_vm

# get VM's IP
vm_ip=$(~/bin/corectl q -i k8solo-01)

#
if [[ "${new_vm}" == "1" ]]
then
    # check internet from VM
    echo " "
    echo "Checking internet availablity on VM..."
    check_internet_from_vm

    # install k8s files on to VM
    install_k8s_files
    #
fi

# generate kubeconfig file if there is no such one file
if [ ! -f "$HOME"/kube-solo/kube/kubeconfig ]; then
    echo " "
    echo "Generating kubeconfig file ..."
    "${res_folder}"/bin/gen_kubeconfig $vm_ip
fi
#

# Set the shell environment variables
# set etcd endpoint
export ETCDCTL_PEERS=http://$vm_ip:2379
# set kubernetes master endpoint
export KUBERNETES_MASTER=http://$vm_ip:8080
# set kubernetes cluster config file path for Helm
export KUBECONFIG=~/kube-solo/kube/kubeconfig
# docker daemon
export DOCKER_HOST=tcp://$vm_ip:2375
export DOCKER_TLS_VERIFY=
export DOCKER_CERT_PATH=

# wait till etcd service is ready
echo " "
echo "Waiting for etcd service to be ready on VM..."
sleep 3
spin='-\|/'
i=1
until curl -o /dev/null http://"$vm_ip":2379 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo "..."
#

# wait for Kubernetes cluster readiness
echo " "
echo "Waiting for Kubernetes cluster to be ready. This can take a bit..."
spin='-\|/'
i=1
until curl -o /dev/null -sIf http://"$vm_ip":8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo "..."
echo " "
echo "Waiting for Kubernetes node to be ready. This can take a bit..."
i=1
until ~/kube-solo/bin/kubectl get nodes | grep -w "k8solo-01" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo "..."
#

if [[ "${new_vm}" == "1" ]]
then
    # attach label to the node
    echo " "
    ~/kube-solo/bin/kubectl label nodes k8solo-01 node=worker1
    # copy add-ons files
    cp "${res_folder}"/k8s/add-ons/*.yaml ~/kube-solo/kubernetes
    install_k8s_add_ons
    # install Helm Tiller
    echo " "
    echo "Installing Helm Tiller..."
    ~/kube-solo/bin/helm init
    #
    echo " "
    echo "kubectl cluster-info:"
    ~/kube-solo/bin/kubectl cluster-info
    echo " "
    echo "Cluster version:"
    CLIENT_INSTALLED_VERSION=$(~/kube-solo/bin/kubectl version | grep "Client Version:" | awk '{print $5}' | awk -v FS='(:"|",)' '{print $2}')
    SERVER_INSTALLED_VERSION=$(~/kube-solo/bin/kubectl version | grep "Server Version:" | awk '{print $5}' | awk -v FS='(:"|",)' '{print $2}')
    echo "Client version: $CLIENT_INSTALLED_VERSION"
    echo "Server version: $SERVER_INSTALLED_VERSION"
    # remove unfinished_setup file
    rm -f ~/kube-solo/logs/unfinished_setup > /dev/null 2>&1
fi
#

echo " "
echo "kubectl get nodes:"
~/kube-solo/bin/kubectl get nodes
echo " "
#

cd ~/kube-solo/kubernetes

# open user's preferred shell
if [[ ! -z "$SHELL" ]]; then
  $SHELL
else
  /bin/bash
fi
