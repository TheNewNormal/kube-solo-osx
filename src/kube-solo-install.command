#!/bin/bash

#  coreos-xhyve-install.command
#

    # create in "kube-solo" all required folders and files at user's home folder where all the data will be stored
    mkdir -p ~/.coreos-xhyve/imgs
    mkdir ~/kube-solo
    ln -s ~/.coreos-xhyve/imgs ~/kube-solo/imgs
    mkdir ~/kube-solo/tmp
    mkdir ~/kube-solo/bin
    mkdir ~/kube-solo/cloud-init
    mkdir ~/kube-solo/fleet
    mkdir ~/kube-solo/kubernetes
    mkdir ~/kube-solo/kube

    # cd to App's Resources folder
    cd "$1"

    # copy files to ~/kube-solo/bin
    cp -f "$1"/files/* ~/kube-solo/bin
    # copy xhyve to bin folder
    cp -f "$1"/bin/xhyve ~/kube-solo/bin
    chmod 755 ~/kube-solo/bin/*

    # copy user-data
    cp -f "$1"/settings/user-data ~/kube-solo/cloud-init
    cp -f "$1"/settings/user-data-format-root ~/kube-solo/cloud-init

    # copy custom.conf
    cp -f "$1"/settings/custom.conf ~/kube-solo

    # copy k8s files
    cp "$1"/k8s/kubectl ~/kube-solo/kube
    chmod 755 ~/kube-solo/kube/kubectl
    cp "$1"/k8s/*.yaml ~/kube-solo/kubernetes
    # linux binaries
    cp "$1"/k8s/kube.tgz ~/kube-solo/kube

    # copy fleet units
    cp -R "$1"/fleet/ ~/kube-solo/fleet
    #

    # check if iTerm.app exists
    App="/Applications/iTerm.app"
    if [ ! -d "$App" ]
    then
        unzip "$1"/files/iTerm2.zip -d /Applications/
    fi

    # initial init
    open -a iTerm.app "$1"/first-init.command

