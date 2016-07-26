#!/bin/bash

#  halt.command

CORECTL_PATH=$(which corectl)
# send halt to VM
if [ "$CORECTL_PATH" == "" ]; then
  /usr/local/sbin/corectl halt k8solo-01
else
  $CORECTL_PATH halt k8solo-01
fi
