#!/bin/bash

#  change sudo password
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

#
save_password

#
echo "The 'sudo' password was changed"
echo " "
pause 'Press [Enter] key to continue...'
