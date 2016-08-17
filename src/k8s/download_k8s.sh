#!/bin/bash

#  download_k8s.command
#  Kube-Solo for macOS
#
#  Created by Rimantas on 03/06/2015.
#  Copyright (c) 2014 Rimantas Mocevicius. All rights reserved.

function pause(){
read -p "$*"
}

rm -f kubectl
rm -f *.tgz

# get latest k8s version
function get_latest_version_number {
 local -r latest_url="https://storage.googleapis.com/kubernetes-release/release/stable.txt"
 curl -Ss ${latest_url}
}

K8S_VERSION=$(get_latest_version_number)

# download latest version of kubectl for macOS
echo "Downloading kubectl $K8S_VERSION for macOS"
curl -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/darwin/amd64/kubectl > kubectl
chmod a+x kubectl

# download latest version of linux k8s binaries
mkdir kube
bins=( kubectl kubelet kube-proxy kube-apiserver kube-scheduler kube-controller-manager )
for b in "${bins[@]}"; do
    curl -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/$b > kube/$b
done

# copy socat file
cp socat/socat kube
#
chmod a+x kube/*
#
curl -L https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz > kube/easy-rsa.tar.gz
tar czvf kube.tgz -C kube .
rm -f kube/*.*
rm -f kube/*
#
echo "Download has finished !!!"
pause 'Press [Enter] key to continue...'
