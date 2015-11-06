#!/bin/bash

#  update_k8s_versions.command
#  Kube-Solo for OS X
#
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# get VM IP
vm_ip=$(cat ~/kube-solo/.env/ip_address)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# copy files to ~/kube-solo/bin
cp -f "${res_folder}"/files/* ~/kube-solo/bin
# copy xhyve to bin folder
cp -f "${res_folder}"/bin/xhyve ~/kube-solo/bin
chmod 755 ~/kube-solo/bin/*

echo "$1"

# download reuired version of k8s files
download_k8s_files_version
#

# generate kubeconfig file
 "${res_folder}"/bin/gen_kubeconfig $vm_ip
#

# restart fleet units
echo "Restarting fleet units:"
# set fleetctl tunnel
export FLEETCTL_ENDPOINT=http://$vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
cd ~/kube-solo/fleet
~/kube-solo/bin/fleetctl stop *.service
sleep 5
~/kube-solo/bin/fleetctl start *.service
#
sleep 8
echo " "
echo "fleetctl list-units:"
~/kube-solo/bin/fleetctl list-units
echo " "

# set kubernetes master
export KUBERNETES_MASTER=http://$vm_ip:8080
echo Waiting for Kubernetes cluster to be ready. This can take a few minutes...
spin='-\|/'
i=1
until ~/kube-solo/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
i=1
until ~/kube-solo/bin/kubectl get nodes | grep $vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
#
echo " "
echo "k8s nodes list:"
~/kube-solo/bin/kubectl get nodes
echo " "
#

echo "Kubernetes update has finished !!!"
pause 'Press [Enter] key to continue...'
