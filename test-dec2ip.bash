#!/bin/bash

debug=1

[[ -z $1 ]] && echo ${0##*/} \<guest id\> && exit 1

source /etc/dnc.conf
source /usr/local/lib/dnclib.bash

echo
guestid=$1
dec2ip
echo ip is $ip
echo

