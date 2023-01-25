#!/bin/bash

[[ -z $1 ]] && echo usage: ${0##*/} guest-name && exit 1
guest=$1

export CLUSTER=/etc/dsh.conf

dsh -e -g xen "xl list $guest 2>/dev/null | sed 1d"
#| cut -f1 -d' '"

