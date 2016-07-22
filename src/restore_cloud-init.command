#!/bin/bash

# restore_cloud-init.command
#

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

LOOP=1
while [ $LOOP -gt 0 ]
do
    VALID_MAIN=0
    echo "'cloud-init/user-data' file will be restored to it's original settings !!!"
    echo "Do you want to continue [y/n]"

    read RESPONSE
    XX=${RESPONSE:=Y}

    if [ $RESPONSE = y ]
    then
        VALID_MAIN=1

        # copy user-data
        cp -R "${res_folder}"/cloud-init/ ~/kube-solo/cloud-init

        echo "-"
        echo "Done, you need to reboot VM to use the restored user-data !!!""
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




