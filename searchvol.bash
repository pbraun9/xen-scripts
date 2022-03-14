#!/bin/bash

[[ ! -f /etc/dnc.conf ]] && echo /etc/dnc.conf not found && exit 1
. /etc/dnc.conf

[[ -z $1 ]] && echo resource minor? && exit 1
minor=$1
res=dnc$minor

dsh -e -g xen lvs | grep $res

