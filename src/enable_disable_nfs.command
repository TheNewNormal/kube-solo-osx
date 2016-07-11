#!/bin/bash

#  change NFS settings
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh


# check if nfs setting is present in file
check=$(cat ~/kube-solo/settings/k8solo-01.toml | grep "shared-homedir" )

if [[ "${check}" = "" ]]
then
    echo '   #shared-homedir = "true"' >> ~/kube-solo/settings/k8solo-01.toml
fi

# update nfs setting
nfs=$(cat ~/kube-solo/settings/k8solo-01.toml | grep "#shared-homedir" )

if [[ "${nfs}" = "" ]]
then
    # disable NFS
    /usr/bin/sed -i "" 's/shared-homedir/#shared-homedir/' ~/kube-solo/settings/k8solo-01.toml
    echo " "
    echo "Shared NFS user home folder was disabled !!!"
else
    # enable NFS
    /usr/bin/sed -i "" 's/#shared-homedir/shared-homedir/' ~/kube-solo/settings/k8solo-01.toml
    echo " "
    echo "Shared NFS user home folder was enabled !!!"
fi


#
echo " "
echo "You need to reboot your VM if it was running ..."
echo " "
pause 'Press [Enter] key to continue...'
