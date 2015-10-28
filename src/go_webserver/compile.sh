#!/bin/bash

# compile kube-solo-web from source

go build kube-solo-web.go
mv -f kube-solo-web ../bin
