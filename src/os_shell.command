#!/bin/bash

#  Pre-set OS shell
#
###DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
###source "${DIR}"/functions.sh

# add ssh key to Keychain
ssh-add -K ~/.ssh/id_rsa &>/dev/null

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# determine corectl path
corectl_path=$(which corectl)
if [ "$corectl_path" == "" ]; then
  corectl_path=/usr/local/sbin/corectl
fi

# get VM IP
vm_ip=$($corectl_path q -i k8solo-01)

# Set the shell environment variables
# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# set etcd endpoint
export ETCDCTL_PEERS=http://$vm_ip:2379

# docker daemon
export DOCKER_HOST=tcp://$vm_ip:2375
export DOCKER_TLS_VERIFY=
export DOCKER_CERT_PATH=

# set kubernetes master endpoint
export KUBERNETES_MASTER=http://$vm_ip:8080
echo " "
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
