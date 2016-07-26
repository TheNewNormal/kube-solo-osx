#!/bin/bash

# destroy extra disk and create new
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

LOOP=1
while [ $LOOP -gt 0 ]
do
    VALID_MAIN=0
    echo "VM will be stopped (if is running) and destroyed !!!"
    echo "Do you want to continue [y/n]"

    read RESPONSE
    XX=${RESPONSE:=Y}

    if [ $RESPONSE = y ]
    then
        VALID_MAIN=1

        # determine corectl path
        corectl_path=$(which corectl)
        if [ "$corectl_path" == "" ]; then
            corectl_path=/usr/local/sbin/corectl
        fi

        # send halt to VM
        $corectl_path halt k8solo-01 > /dev/null 2>&1

        # delete data image
        rm -f ~/kube-solo/data.img > /dev/null 2>&1

        # remove unfinished_setup file
        rm -f ~/kube-solo/logs/unfinished_setup > /dev/null 2>&1

        echo "-"
        echo "Done, please start VM with 'Up' and the new VM will be created ..."
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




