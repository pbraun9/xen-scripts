#!/bin/bash
set -e

[[ -z $1 ]] && echo "${0##*/} <GUEST-NAME>" && exit 1
guest=$1

source /etc/dnc.conf
[[ -z $hostprefix ]] && echo define hostprefix && exit 1

alive=`dsh -e -g xen "xl list | grep -E \"^$guest[[:space:]]+\"" | cut -f1 -d:`
[[ -n $alive ]] && echo $guest already lives on $alive && exit 1

guestpath=/data/guests/$guest
conf=$guestpath/$guest
[[ ! -f $conf ]] && echo $conf cannot be found && exit 1

(( id = RANDOM % 3 + 1 ))
node=${hostprefix}$id

ssh $node "xl create $conf" && echo GUEST $guest HAS BEEN STARTED ON NODE $node
ssh $node "echo up > $guestpath/state"

