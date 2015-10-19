#!/bin/bash

#  change release channel
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh


# Set release channel
release_channel

#
echo " "
echo "The 'custom.conf' file was updated to $channel channel !!!"
echo "You need to run from menu 'Setup->Destroy VM' to get VM destroyed"
echo "and new VM will be created on the next 'Up'..."
echo "If there is no $channel channel image, it will be downloaded automaticly..."
pause 'Press [Enter] key to continue...'
