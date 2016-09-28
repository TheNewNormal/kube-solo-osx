#!/bin/bash

#  download_dashboard.command
#  Kube-Solo for macOS
#
#  Created by Rimantas on 03/06/2015.
#  Copyright (c) 2014 Rimantas Mocevicius. All rights reserved.

function pause(){
read -p "$*"
}

rm -f add-ons/dashboard-controller.yaml
rm -f add-ons/dashboard-service.yaml

#
curl -L https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dashboard/dashboard-controller.yaml > add-ons/dashboard-controller.yaml
curl -L https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dashboard/dashboard-service.yaml > add-ons/dashboard-service.yaml

#
echo "Download has finished !!!"
pause 'Press [Enter] key to continue...'
