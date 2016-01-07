#!/bin/bash

# destroy extra disk and create new
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-solo/.env/resouces_path)

# get VM IP
vm_ip=$("${res_folder}"/bin/corectl q -i k8solo-01)

# get password for sudo
my_password=$(security find-generic-password -wa kube-solo-app)
# reset sudo
sudo -k

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

        # enable sudo
        echo -e "$my_password\n" | sudo -Sv > /dev/null 2>&1

        # send halt to VM
        echo -e "$my_password\n" | sudo -S "${res_folder}"/bin/corectl halt k8solo-01 > /dev/null 2>&1

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




