#!/bin/bash

[[ -z $1 ]] && echo -e ${0##*/} GUEST-NAME\\n && exit 1
guest=$1
guestpath=/data/guests/$guest

node=`dsh -e -g xen "xl list | grep -E \"^$guest[[:space:]]+\"" | cut -f1 -d:`
[[ -z $node ]] && echo $guest does not seem to be alive && exit 1
(( `echo "$node" | wc -l` > 1 )) && echo -e "ERROR guest lives on multiple nodes!\n$node" && exit 1

ssh $node "xl shu $guest" && echo -n SHUTTING DOWN GUEST $guest ON NODE $node

(( maxsec = 25 ))
(( sec = 0 ))
until (( sec > maxsec )); do
	sleep 1
	tmp=`ssh $node "xl list | grep -E \"^$guest[[:space:]]+\"" | cut -f1 -d:`
	[[ -n $tmp ]] && echo -n .
	[[ -z $tmp ]] && echo DONE && break
	(( sec++ ))
	unset tmp
done

tmp=`ssh $node "xl list | grep -E \"^$guest[[:space:]]+\"" | cut -f1 -d:`
[[ -n $tmp ]] && echo $guest failed to shut down gracefully && ssh $node xl destroy $guest
unset tmp

ssh $node "echo down > $guestpath/state"

