#!/bin/bash

# destroy extra disk and create new
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# get VM IP
vm_ip=$(<~/kube-solo/.env/ip_address)

LOOP=1
while [ $LOOP -gt 0 ]
do
    VALID_MAIN=0
    echo "VM will be stopped and destroyed !!!"
    echo "Do you want to continue [y/n]"

    read RESPONSE
    XX=${RESPONSE:=Y}

    if [ $RESPONSE = y ]
    then
        VALID_MAIN=1

        # check VM status
        status=$(ps aux | grep "[k]ube-solo/bin/xhyve" | awk '{print $2}')
        if [[ $status = *[!\ ]* ]]; then
            echo " "
            echo "Kube Solo is running, it will be stopped !!!"

            # Stop VM
            ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet -o ConnectTimeout=3 core@$vm_ip sudo halt

            # just in case run
            kill_xhyve >/dev/null 2>&1

            # wait till VM is stopped
            echo " "
            echo "Waiting for VM to shutdown..."
            spin='-\|/'
            i=1
            until "${res_folder}"/check_vm_status.command | grep "VM is stopped" >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
        fi

        # delete root image
        rm -f ~/kube-solo/root.img

        # delete password in keychain
        security 2>&1 >/dev/null delete-generic-password -a kube-solo-app 2>&1 >/dev/null

        echo "-"
        echo "Done, please start VM with 'Up' and the VM will be recreated ..."
        echo " "
        pause 'Press [Enter] key to continue...'
        LOOP=0
    fi

    if [ $RESPONSE = n ]
    then
        VALID_MAIN=1
        LOOP=0
    fi

    if [ $VALID_MAIN != y ] || [ $VALID_MAIN != n ]
    then
        continue
    fi
done




