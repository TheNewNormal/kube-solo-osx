#!/bin/bash

#  update.command
#  Kube-Solo for OS X
#
#  Created by Rimantas on 03/06/2015.
#  Copyright (c) 2014 Rimantas Mocevicius. All rights reserved.

function pause(){
read -p "$*"
}

cd ~/kube-solo/kube
machine_status=$(vagrant status | grep -o -m 1 'poweroff\|not created')

if [ "$machine_status" = "poweroff" ]
then
    echo " "
    echo "Kube-Solo VM is not running !!!"
    pause 'Press [Enter] key to continue...'
elif [ "$machine_status" = "not created" ]
then
    echo " "
    echo "Kube-Solo VM is not created !!!"
    pause 'Press [Enter] key to continue...'
else

    # get App's Resources folder
    res_folder=$(cat ~/kube-solo/.env/resouces_path)

    # copy gsed to ~/kube-solo/bin
    cp -f "${res_folder}"/gsed ~/kube-solo/bin
    chmod 755 ~/kube-solo/bin/gsed

    # copy wget with https support to ~/kube-solo/bin
    cp -f "${res_folder}"/wget ~/kube-solo/bin
    chmod 755 ~/kube-solo/bin/wget

    #
    cd ~/kube-solo/kube
    vagrant up

    # download latest versions of etcdctl and fleetctl
    cd ~/kube-solo/kube
    LATEST_RELEASE=$(vagrant ssh k8solo-01 -c "etcdctl --version" | cut -d " " -f 3- | tr -d '\r' )
    cd ~/kube-solo/bin
    echo "Downloading etcdctl $LATEST_RELEASE for OS X"
    curl -k -L -o etcd.zip "https://github.com/coreos/etcd/releases/download/v$LATEST_RELEASE/etcd-v$LATEST_RELEASE-darwin-amd64.zip"
    unzip -j -o "etcd.zip" "etcd-v$LATEST_RELEASE-darwin-amd64/etcdctl"
    rm -f etcd.zip
    echo "etcdctl was copied to ~/kube-solo/bin"
    echo " "

    #
    cd ~/kube-solo/kube
    LATEST_RELEASE=$(vagrant ssh k8solo-01 -c 'fleetctl version' | cut -d " " -f 3- | tr -d '\r')
    cd ~/kube-solo/bin
    echo "Downloading fleetctl v$LATEST_RELEASE for OS X"
    curl -k -L -o fleet.zip "https://github.com/coreos/fleet/releases/download/v$LATEST_RELEASE/fleet-v$LATEST_RELEASE-darwin-amd64.zip"
    unzip -j -o "fleet.zip" "fleet-v$LATEST_RELEASE-darwin-amd64/fleetctl"
    rm -f fleet.zip
    echo "fleetctl was copied to ~/kube-solo/bin "
    echo " "

    #
    echo "Reinstalling updated fleet units to '~/kube-solo/fleet' folder:"
    # set fleetctl tunnel
    export FLEETCTL_ENDPOINT=http://172.19.17.99:2379
    export FLEETCTL_DRIVER=etcd
    export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
    cd ~/kube-solo/fleet

    #
    if [ "$(diff "$res_folder"/fleet/fleet-ui.service ~/kube-solo/fleet/fleet-ui.service | tr -d '\n' | cut -c1-4 )" != "" ]
    then
        echo "updating fleet-ui.service!"
        cp -fr "$res_folder"/fleet/fleet-ui.service ~/kube-solo/fleet/fleet-ui.service
        ~/kube-solo/bin/fleetctl destroy fleet-ui.service
        ~/kube-solo/bin/fleetctl start fleet-ui.service
    fi

    if [ "$(diff "$res_folder"/fleet/kube-apiserver.service ~/kube-solo/fleet/kube-apiserver.service | tr -d '\n' | cut -c1-4 )" != "" ]
    then
        echo "updating kube-apiserver.service!"
        cp -fr "$res_folder"/fleet/kube-apiserver.service ~/kube-solo/fleet/kube-apiserver.service
        ~/kube-solo/bin/fleetctl destroy kube-apiserver.service
        ~/kube-solo/bin/fleetctl start kube-apiserver.service
    fi

    if [ "$(diff "$res_folder"/fleet/kube-controller-manager.service ~/kube-solo/fleet/kube-controller-manager.service | tr -d '\n' | cut -c1-4 )" != "" ]
    then
        echo "updating kube-controller-manager.service!"
        cp -fr "$res_folder"/fleet/kube-controller-manager.service ~/kube-solo/fleet/kube-controller-manager.service
        ~/kube-solo/bin/fleetctl destroy kube-kubeler-manager.service
        ~/kube-solo/bin/fleetctl start kube-kubeler-manager.service
    fi

    if [ "$(diff "$res_folder"/fleet/kube-scheduler.service ~/kube-solo/fleet/kube-scheduler.service | tr -d '\n' | cut -c1-4 )" != "" ]
    then
        echo "updating kube-scheduler.service!"
        cp -fr "$res_folder"/fleet/kube-scheduler.service ~/kube-solo/fleet/kube-scheduler.service
        ~/kube-solo/bin/fleetctl destroy kube-scheduler.service
        ~/kube-solo/bin/fleetctl start kube-scheduler.service
    fi

    if [ "$(diff "$res_folder"/fleet/kube-kubelet.service ~/kube-solo/fleet/kube-kubelet.service | tr -d '\n' | cut -c1-4 )" != "" ]
    then
        echo "updating kube-kubelet.service!"
        cp -fr "$res_folder"/fleet/kube-kubelet.service ~/kube-solo/fleet/kube-kubelet.service
        ~/kube-solo/bin/fleetctl destroy kube-kubelet.service
        ~/kube-solo/bin/fleetctl start kube-kubelet.service
    fi

    if [ "$(diff "$res_folder"/fleet/kube-proxy.service ~/kube-solo/fleet/kube-proxy.service | tr -d '\n' | cut -c1-4 )" != "" ]
    then
        echo "updating kube-proxy.service!"
        cp -fr "$res_folder"/fleet/kube-proxy.service ~/kube-solo/fleet/kube-proxy.service
        ~/kube-solo/bin/fleetctl destroy kube-proxy.service
        ~/kube-solo/bin/fleetctl start kube-proxy.service
    fi

    #
    echo "Finished updating fleet units"
    ~/kube-solo/bin/fleetctl list-units
    echo " "

    # set kubernetes master
    export KUBERNETES_MASTER=http://172.19.17.99:8080
    echo Waiting for Kubernetes cluster to be ready. This can take a few minutes...
    spin='-\|/'
    i=1
    until ~/kube-solo/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
    i=0
    until ~/kube-solo/bin/kubectl get nodes | grep 172.19.17.99 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
    #
    echo " "
    echo "k8s nodes list:"
    ~/kube-solo/bin/kubectl get nodes
    echo " "

    #
    echo "Update has finished !!!"
    pause 'Press [Enter] key to continue...'

fi

