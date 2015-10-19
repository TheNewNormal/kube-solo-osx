#!/bin/bash

# get go binary of docker2aci

rm -f ~/go/bin/docker2aci
go get github.com/appc/docker2aci
cp -f ~/go/bin/docker2aci ../files
