#!/bin/bash

#  download_k8s.command
#  Kube-Solo for macOS
#
#  Created by Rimantas on 03/06/2015.
#  Copyright (c) 2014 Rimantas Mocevicius. All rights reserved.

function pause(){
read -p "$*"
}

#
rm -f add-ons.tgz
#
tar czvf add-ons.tgz -C add-ons .
#
