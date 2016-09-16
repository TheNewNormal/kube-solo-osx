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
vm_ip=$(~/bin/corectl q -i k8solo-01)

# Set the shell environment variables
# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# set etcd endpoint
export ETCDCTL_PEERS=http://$vm_ip:2379

# set kubernetes master endpoint
export KUBERNETES_MASTER=http://$vm_ip:8080

# set kubernetes cluster config file path for k8s API and Helm
export KUBECONFIG=~/kube-solo/kube/kubeconfig
export HELM_HOST=$vm_ip:32767

# docker daemon
export DOCKER_HOST=tcp://$vm_ip:2375
export DOCKER_TLS_VERIFY=
export DOCKER_CERT_PATH=

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
