#!/bin/bash
set -e

[[ -z $1 ]] && echo ${0##*/} GUEST-NAME && exit 1
guest=$1

node=`dsh -e -g xen "xl list | grep -E \"^$guest[[:space:]]+\"" | cut -f1 -d:`
[[ -n $node ]] && echo $guest already lives on $node exit 1

(( nodeid = RANDOM % 3 + 1 ))
node=slack${nodeid}

guestpath=/data/guests/$guest
conf=$guestpath/$guest
[[ ! -f $conf ]] && echo $conf cannot be found && exit 1

ssh $node "xl create $conf" && echo GUEST $guest HAS BEEN STARTED ON NODE $node
ssh $node "echo up > $guestpath/state"

