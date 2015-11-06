#!/bin/bash

# up.command
#

# tidy up after old version
rm -f ~/kube-solo/.env/password 2>&1 >/dev/null

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# copy xhyve to bin folder
cp -f "${res_folder}"/bin/xhyve ~/kube-solo/bin
chmod 755 ~/kube-solo/bin/xhyve

# check for password in Keychain
my_password=$(security 2>&1 >/dev/null find-generic-password -wa kube-solo-app)
if [ "$my_password" = "security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain." ]
then
    echo " "
    echo "Saved password in 'Keychain' is not found: "
    # save user password to Keychain
    save_password
fi


# Check if set channel's images are present
check_for_images

new_vm=0
# check if root disk exists, if not create it
if [ ! -f $HOME/kube-solo/root.img ]; then
    echo " "
    echo "ROOT disk does not exist, it will be created now ..."
    create_root_disk
    new_vm=1
fi

# Start VM
rm -f ~/kube-solo/.env/.console
echo " "
echo "Starting VM ..."
echo " "
"${res_folder}"/bin/dtach -n ~/kube-solo/.env/.console -z "${res_folder}"/start_VM.command
#

# wait till VM is booted up
echo "You can connect to VM console from menu 'Attach to VM's console' "
echo "When you done with console just close it's window/tab with CMD+W "
echo " "
echo "Waiting for VM to boot up..."
spin='-\|/'
i=1
while [ ! -f ~/kube-solo/.env/ip_address ]; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
# get VM IP
vm_ip=$(cat ~/kube-solo/.env/ip_address);
# wait for VM to be ready
i=1
while ! ping -c1 $vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done

# Set the environment variables
# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# set etcd endpoint
export ETCDCTL_PEERS=http://$vm_ip:2379
# wait till VM is ready
echo " "
echo "Waiting for VM to be ready..."
spin='-\|/'
i=1
until curl -o /dev/null http://$vm_ip:2379 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
#

# set fleetctl endpoint
export FLEETCTL_ENDPOINT=http://$vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
#
sleep 1

#
echo "fleetctl list-machines:"
fleetctl list-machines
#
if [ $new_vm = 1 ]
then
    install_k8s_files
    #
    echo "  "
    deploy_fleet_units
fi

echo " "
# set kubernetes master
export KUBERNETES_MASTER=http://$vm_ip:8080
echo Waiting for Kubernetes cluster to be ready. This can take a few minutes...
spin='-\|/'
i=1
until curl -o /dev/null http://$vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-solo/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
i=1
until ~/kube-solo/bin/kubectl get nodes | grep $vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#
if [ $new_vm = 1 ]
then
    # attach label to the node
    ~/kube-solo/bin/kubectl label nodes $vm_ip node=worker1
    # copy add-ons files
    cp "${res_folder}"/k8s/*.yaml ~/kube-solo/kubernetes
    install_k8s_add_ons
    #
fi
#
echo " "
echo "kubernetes nodes list:"
~/kube-solo/bin/kubectl get nodes
echo " "
#

cd ~/kube-solo/kubernetes

# open bash shell
/bin/bash
