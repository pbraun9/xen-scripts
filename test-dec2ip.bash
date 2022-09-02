#!/bin/bash

debug=1

[[ -z $1 ]] && echo ${0##*/} \<guest id\> && exit 1

source /etc/dnc.conf
source /root/xen/newguest-functions.bash

echo
guestid=$1
dec2ip
echo ip is $ip
echo

