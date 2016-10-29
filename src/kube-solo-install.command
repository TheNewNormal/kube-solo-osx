#!/bin/bash

#  kube-solo-install.command
#

    # create in "kube-solo" all required folders and files at user's home folder where all the data will be stored
    mkdir ~/kube-solo
    mkdir ~/kube-solo/tmp
    mkdir ~/kube-solo/logs
    mkdir ~/kube-solo/bin
    mkdir ~/kube-solo/cloud-init
    mkdir ~/kube-solo/settings
    mkdir ~/kube-solo/kubernetes
    mkdir ~/kube-solo/kube

    # cd to App's Resources folder
    cd "$1"

    # copy bin files to ~/kube-solo/bin
    cp -f "$1"/bin/* ~/kube-solo/bin
    rm -f "$HOME"/kube-solo/bin/gen_kubeconfig
    chmod +x ~/kube-solo/bin/*

    # copy ksolo file to ~/bin
    cp -f "$1"/bin/ksolo ~/bin

    # copy user-data
    cp -f "$1"/cloud-init/* ~/kube-solo/cloud-init

    # copy settings
    cp -f "$1"/settings/* ~/kube-solo/settings

    # copy k8s files
    cp "$1"/k8s/kubectl ~/kube-solo/bin
    chmod +x ~/kube-solo/bin/kubectl
    cp "$1"/k8s/add-ons/*.yaml ~/kube-solo/kubernetes
    # linux binaries
    cp "$1"/k8s/kube.tgz ~/kube-solo/kube

    # check if iTerm.app exists
    App="/Applications/iTerm.app"
    if [ ! -d "$App" ]
    then
        unzip "$1"/files/iTerm2.zip -d /Applications/
    fi

    # initial init
    tmuxcmd=/usr/local/bin/tmux
    ${tmuxcmd} list-sessions \
        && ${tmuxcmd} new-window -n "kube-solo" "$1"/first-init.command \
        || open -a iTerm.app "$1"/first-init.command

