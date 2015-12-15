#!/bin/bash

# up.command
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# add ssh key to Keychain
ssh-add -K ~/.ssh/id_rsa &>/dev/null

# check if iTerm.app exists
App="/Applications/iTerm.app"
if [ ! -d "$App" ]
then
    unzip "${res_folder}"/files/iTerm2.zip -d /Applications/
fi

# copy bin files to ~/kube-solo/bin
cp -f "${res_folder}"/bin/* ~/kube-solo/bin
rm -f ~/kube-solo/bin/gen_kubeconfig
chmod 755 ~/kube-solo/bin/*

# check for password in Keychain
my_password=$(security 2>&1 >/dev/null find-generic-password -wa kube-solo-app)
if [ "$my_password" = "security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain." ]
then
    echo " "
    echo "Saved password could not be found in the 'Keychain': "
    # save user password to Keychain
    save_password
fi

new_vm=0
# check if root disk exists, if not create it
if [ ! -f $HOME/kube-solo/root.img ]; then
    echo " "
    echo "ROOT disk does not exist, it will be created now ..."
    create_root_disk
    new_vm=1
fi

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

# Set the environment variables
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
export FLEETCTL_TUNNEL=
export FLEETCTL_ENDPOINT=http://$vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
#
sleep 3

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
echo "Waiting for Kubernetes cluster to be ready. This can take a few minutes..."
spin='-\|/'
i=1
until curl -o /dev/null -sIf http://$vm_ip:8080 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-solo/bin/kubectl get nodes | grep $vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#

if [ $new_vm = 1 ]
then
    # attach label to the node
    echo " "
    ~/kube-solo/bin/kubectl label nodes $vm_ip node=worker1
    # copy add-ons files
    cp "${res_folder}"/k8s/*.yaml ~/kube-solo/kubernetes
    install_k8s_add_ons "$vm_ip"
    #
fi
#
echo "kubernetes nodes list:"
~/kube-solo/bin/kubectl get nodes
echo " "
#

cd ~/kube-solo/kubernetes

# open bash shell
/bin/bash
