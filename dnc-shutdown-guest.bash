#!/bin/bash

source /usr/local/lib/dnclib.bash

[[ -z $1 ]] && echo -e ${0##*/} GUEST-NAME\\n && exit 1
guest=$1
guestpath=/data/guests/$guest

[[ ! -d $guestpath/ ]] && bomb $guestpath/ not found - shared-disk cluster is down?

#echo down > $guestpath/state

#node=`dsh -e -g xen "xl list | grep -E \"^$guest[[:space:]]+\"" | cut -f1 -d:`
#[[ -z $node ]] && echo $guest does not seem to be alive && exit 1
#(( `echo "$node" | wc -l` > 1 )) && echo -e "ERROR guest lives on multiple nodes!\n$node" && exit 1

# we are root already
node=`/usr/local/sbin/dnc-running-guest.bash $guest | cut -f1 -d:`
[[ -z $node ]] && bomb could not determine on what node guest $guest lives on
(( debug > 0 )) && echo guest $guest lives on $node

# outputs Shutting down domain 9 and Connection to pmr3 closed. hence w/o -n
echo SHUTTING DOWN GUEST $guest ON NODE $node

#echo gracefully shutting down guest $guest on node $node
ssh $node -t xl shutdown $guest

(( maxsec = 25 ))
(( sec = 0 ))
until (( sec > maxsec )); do
	sleep 1
	tmp=`ssh $node "xl list | grep -E \"^$guest[[:space:]]+\"" | cut -f1 -d:`
	#tmp=`ssh $node xl list $guest | cut -f1 -d:`
	#dnc1030 is an invalid domain identifier (rc=-6)
	[[ -n $tmp ]] && echo -n .
	[[ -z $tmp ]] && echo DONE && break
	(( sec++ ))
	unset tmp
done
echo

tmp=`ssh $node "xl list | grep -E \"^$guest[[:space:]]+\"" | cut -f1 -d:`
#dnc1024 is an invalid domain identifier (rc=-6)
#tmp=`ssh $node xl list $guest | cut -f1 -d:`
[[ -n $tmp ]] \
	&& echo -n $guest failed to shut down gracefully hence going for cold poweroff... \
	&& ssh $node xl destroy $guest && echo done
unset tmp
echo

