#!/bin/bash
echo

[[ -z $1 ]] && echo -e ${0##*/} GUEST-NAME\\n && exit 1
guest=$1

(( nodeid = RANDOM % 3 + 1 ))
node=slack${nodeid}

guestpath=/data/guests/$guest
conf=$guestpath/$guest
[[ ! -f $conf ]] && echo $conf cannot be found && exit 1

ssh $node echo up > $guestpath/state
ssh $node xl create $conf && echo -e \\nGUEST $guest HAS BEEN STARTED ON NODE $node\\n

