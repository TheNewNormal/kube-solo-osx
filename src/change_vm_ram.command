#!/bin/bash

#  change_vm_ram.command

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

#
change_vm_ram

#
((ram_size=$new_ram_size/1024))

echo "You need to reload your VM if it is running or on next VM's boot new $ram_size GB RAM will be used ..."
echo " "
pause 'Press [Enter] key to continue...'
