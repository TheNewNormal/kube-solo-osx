#!/bin/bash

# compile corectl binary

current_folder=$(pwd)

rm -rf $GOPATH/src/github.com/TheNewNormal/corectl

#
mkdir -p $GOPATH/src/github.com/TheNewNormal
#
cd $GOPATH/src/github.com/TheNewNormal
#
git clone https://github.com/TheNewNormal/corectl

# build
cd corectl
make

#
cd $current_folder
cp -f $GOPATH/src/github.com/TheNewNormal/corectl/corectl ../bin

# clean up go folder
rm -fr $GOPATH/src/github.com/TheNewNormal/corectl

