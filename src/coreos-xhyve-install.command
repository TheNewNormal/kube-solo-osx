#!/bin/bash

#  coreos-xhyve-install.command
#

    # create in "kube-solo" all required folders and files at user's home folder where all the data will be stored
    mkdir -p ~/.coreos-xhyve/imgs
    mkdir ~/kube-solo
    mkdir ~/kube-solo/tmp
    mkdir ~/kube-solo/bin
    mkdir ~/kube-solo/cloud-init
    mkdir ~/kube-solo/fleet
    ln -s ~/.coreos-xhyve/imgs ~/kube-solo/imgs

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
    cp -f "$1"/settings/custom-format-root.conf ~/kube-solo

    # initial init
    open -a "$1"/iTerm.app "$1"/first-init.command
