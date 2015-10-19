#!/bin/bash

echo "  "
echo "Please type extra disk size in GB followed by [ENTER]:"
echo -n [5]: 
read disk_size

if [ -z "$disk_size" ]
then 
    echo "Creating 5 GB disk ..."
    dd if=/dev/zero of=extra.img bs=1024 count=0 seek=$[1024*5000]
else
    echo "Creating $disk_size GB disk ..."
    dd if=/dev/zero of=extra.img bs=1024 count=0 seek=$[1024*$disk_size]
fi
#
