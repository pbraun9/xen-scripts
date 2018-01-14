#!/bin/ksh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/pkg/bin:/usr/pkg/sbin:$HOME/bin

[[ ! `uname` = NetBSD ]] && this script is supposed to run on NetBSD systems && exit 1
[[ -z $1 ]] && hostname argument missing && exit 1

echo $1 > /etc/myname
hostname $1
echo `ifconfig xennet0 | grep 'inet ' | awk '{print $2}'` $1 >> /etc/hosts
cat /etc/hosts

