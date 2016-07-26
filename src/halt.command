#!/bin/bash

#  halt.command

# determine corectl path
CORECTL_PATH=$(which corectl)
if [ "$CORECTL_PATH" == "" ]; then
  CORECTL_PATH=/usr/local/sbin/corectl
fi

# send halt to VM
$CORECTL_PATH halt k8solo-01
