#!/bin/bash

debug=1

[[ -z $1 ]] && echo \<drbd minor\>? && exit 1

source /root/xen/newguest-functions.bash
source /etc/dnc.conf

echo
minor=$1
dec2ip
echo 10.1.$suffix
echo

