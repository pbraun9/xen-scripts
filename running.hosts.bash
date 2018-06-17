#!/bin/bash

echo HARDWARE
dsh -e -g cluster "dmidecode -t system | grep 'Product Name'"
echo ''

echo XEN VERSIONS
dsh -e -g xen "xl dmesg | head | grep 'Xen version' | sed 's/(gcc .*$//'"
echo ''

echo LINUX VERSIONS
dsh -e -g cluster "uname -r"
echo ''

echo FILE-SYSTEMS
#dsh -e -g cluster "file -sL /dev/sda1"
dsh -e -g cluster "mount | egrep '(^/dev|type nfs[^d])'"
echo ''

echo MEMORY \(MB\)
dsh -e -g cluster "free -m | grep ^Mem"
echo ''

echo INTERNET \(ping 208.67.220.220\)
dsh -e -g cluster "ping -c1 -W1 208.67.220.220 >/dev/null && echo OK || echo NOK"
echo''

echo INTERNET \(ping opendns\)
dsh -e -g cluster "ping -c1 -W1 opendns.com >/dev/null && echo OK || echo NOK"
echo ''

