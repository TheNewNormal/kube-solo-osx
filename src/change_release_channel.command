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
echo "CoreOS release channel was updated to '$channel' !!!"
echo "You need to reload your VM if it is running or on next VM's boot new '$channel' ISO will be used ..."
echo " "
pause 'Press [Enter] key to continue...'
