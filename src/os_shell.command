#!/bin/bash

#  Pre-set OS shell
#
###DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
###source "${DIR}"/functions.sh

# add ssh key to Keychain
ssh-add -K ~/.ssh/id_rsa &>/dev/null

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# get VM IP
vm_ip=$(/usr/local/sbin/corectl q -i k8solo-01)

# Set the shell environment variables
# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# set etcd endpoint
export ETCDCTL_PEERS=http://$vm_ip:2379
echo " "

# set kubernetes master endpoint
export KUBERNETES_MASTER=http://$vm_ip:8080
echo "kubectl get nodes:"
kubectl get nodes
echo " "

#
echo "Assigned static IP to VM/node: $vm_ip"
echo " "
#

cd ~/kube-solo

# open user's preferred shell
if [[ ! -z "$SHELL" ]]; then
    $SHELL
else
    /bin/bash
fi
