#!/bin/bash
echo

[[ -z $1 ]] && echo -e ${0##*/} GUEST-NAME\\n && exit 1
guest=$1
guestpath=/data/guests/$guest

node=`dsh -e -g xen "xl list | grep \"^$guest \"" | cut -f1 -d:`

[[ -z $node ]] && echo guest $guest does not seem to be alive && exit 1

(( `echo "$node" | wc -l` > 1 )) &&\
	echo ERROR guest lives on multiple nodes! &&\
	echo "$liveson" && exit 1

ssh $node echo down > $guestpath/state
ssh $node xl shu $guest && echo -e \\nSHUTTING DOWN GUEST $guest ON NODE $node\\n

