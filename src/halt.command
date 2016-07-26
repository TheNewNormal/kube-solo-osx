#!/bin/bash

#  halt.command

# determine corectl path
corectl_path=$(which corectl)
if [ "$corectl_path" == "" ]; then
  corectl_path=/usr/local/sbin/corectl
fi

# send halt to VM
$corectl_path halt k8solo-01
