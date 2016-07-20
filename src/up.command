#!/bin/bash

# up.command
#

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
rsync -r --verbose --exclude 'helmc' "${res_folder}"/bin/* ~/kube-solo/bin/ > /dev/null 2>&1
rm -f ~/kube-solo/bin/gen_kubeconfig
chmod 755 ~/kube-solo/bin/*

# add ssh key to Keychain
if ! ssh-add -l | grep -q ssh/id_rsa; then
  ssh-add -K ~/.ssh/id_rsa &>/dev/null
fi

# set variable to 0
new_vm=0

# check if root disk exists, if not create it
if [ ! -f "$HOME"/kube-solo/data.img ]; then
    echo " "
    echo "Data disk does not exist, it will be created now ..."
    create_data_disk
    new_vm=1
fi

# Start VM
start_vm

# get VM's IP
vm_ip=$(/usr/local/sbin/corectl q -i k8solo-01)

#
if [[ "${new_vm}" == "1" ]]
then
    # check internet from VM
    echo " "
    echo "Checking internet availablity on VM..."
    check_internet_from_vm

    # download latest version of fleetctl and helmc clients
    download_osx_clients
    #

    # install k8s files on to VM
    install_k8s_files
    #
fi

# generate kubeconfig file if there is no such one file
if [ ! -f "$HOME"/kube-solo/kube/kubeconfig ]; then
    echo " "
    echo "Generate kubeconfig file ..."
    "${res_folder}"/bin/gen_kubeconfig "$vm_ip"
fi
#

# Set the shell environment variables
# set etcd endpoint
export ETCDCTL_PEERS=http://$vm_ip:2379

# wait till etcd service is ready
echo " "
echo "Waiting for etcd service to be ready on VM..."
spin='-\|/'
i=1
until curl -o /dev/null http://"$vm_ip":2379 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
#

# set fleetctl endpoint
export FLEETCTL_TUNNEL=
export FLEETCTL_ENDPOINT=http://$vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
#
if [[ "${new_vm}" == "1" ]]
then
    # restart fleet on VM
    /usr/local/sbin/corectl ssh k8solo-01 "sudo systemctl restart fleet"
    sleep 2

    echo " "
    echo "fleetctl list-machines:"
    fleetctl list-machines
    echo " "
    #
    start_fleet_units
fi

echo " "
# set kubernetes master
export KUBERNETES_MASTER=http://$vm_ip:8080
echo "Waiting for Kubernetes cluster to be ready. This can take a bit..."
spin='-\|/'
i=1
until curl -o /dev/null -sIf http://"$vm_ip":8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-solo/bin/kubectl get nodes | grep -w "k8solo-01" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#

if [[ "${new_vm}" == "1" ]]
then
    # attach label to the node
    echo " "
    ~/kube-solo/bin/kubectl label nodes k8solo-01 node=worker1
    # copy add-ons files
    cp "${res_folder}"/k8s/*.yaml ~/kube-solo/kubernetes
    install_k8s_add_ons
    #
fi
#

echo " "
echo "kubectl get nodes:"
~/kube-solo/bin/kubectl get nodes
echo " "
#

#
echo "Assigned static IP to VM: $vm_ip"
echo " "
#

cd ~/kube-solo/kubernetes

# open bash shell
/bin/bash
