#!/bin/bash

# compile xhyve from source

git clone https://github.com/mist64/xhyve
cd xhyve
make
#sudo chown root build/xhyve
#sudo chmod +s build/xhyve

cp -f build/xhyve ../../bin
cd ..
rm -rf xhyve
../bin/xhyve -v
