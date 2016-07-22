#!/bin/bash

#  update_k8s_versions.command
#  Kube-Solo for macOS
#
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# get VM IP
vm_ip=$(/usr/local/sbin/corectl q -i k8solo-01)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-solo/bin:$PATH

# copy files to ~/kube-solo/bin
cp -f "${res_folder}"/bin/* ~/kube-solo/bin
rm -f "$HOME"/kube-solo/bin/gen_kubeconfig
chmod 755 ~/kube-solo/bin/*

echo " "
# download required version of k8s files
k8s_upgrade=0
download_k8s_files_version
if [ $k8s_upgrade -eq 0 ]; then
    exit 0
fi
#

# generate kubeconfig file
echo Generate kubeconfig file ...
"${res_folder}"/bin/gen_kubeconfig $vm_ip
echo " "
#

# trigger k8s units restart on VM
echo " "
echo "Restarting Kubernetes systemd units on VM ..."
/usr/local/sbin/corectl ssh k8solo-01 "sudo /opt/sbin/restart-kube-units.sh"
#&>/dev/null
echo " "

# set kubernetes master
export KUBERNETES_MASTER=http://$vm_ip:8080
# wait for Kubernetes cluster readiness
echo "Waiting for Kubernetes cluster to be ready. This can take a bit..."
spin='-\|/'
i=1
until ~/kube-solo/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
echo "..."
echo " "
echo "Waiting for Kubernetes node to be ready. This can take a bit..."
i=1
until ~/kube-solo/bin/kubectl get nodes | grep -w "k8solo-01" | grep -w "Ready" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo "..."
echo " "
#
echo " "
echo "k8s nodes list:"
~/kube-solo/bin/kubectl get nodes
echo " "
#
echo "Cluster version:"
CLIENT_INSTALLED_VERSION=$(~/kube-solo/bin/kubectl version | grep "Client Version:" | awk '{print $5}' | awk -v FS='(:"|",)' '{print $2}')
SERVER_INSTALLED_VERSION=$(~/kube-solo/bin/kubectl version | grep "Server Version:" | awk '{print $5}' | awk -v FS='(:"|",)' '{print $2}')
echo "Client version: $CLIENT_INSTALLED_VERSION"
echo "Server version: $SERVER_INSTALLED_VERSION"
echo " "
#
echo "Cluster info:"
~/kube-solo/bin/kubectl cluster-info
echo " "

echo "Kubernetes cluster update has finished !!!"
echo " "
pause 'Press [Enter] key to continue...'
echo " "
