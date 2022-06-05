#!/bin/bash

# possible to run multiple times even if it fails
#set -e

[[ -z $1 ]] && echo "usage: ${0##*/} <RESOURCE/GUEST>" && exit 1
guest=$1

source /etc/dnc.conf
[[ -z $nodes ]] && echo \$nodes not defined && exit 1

/root/xen/shuguest.bash $guest
echo

rm -rf /data/guests/$guest/

for node in $nodes; do
	echo node $node

	echo resource $guest down
	ssh $node "drbdadm down $guest && echo done"

	echo -n remove resource $guest ...
	ssh $node "rm -f /etc/drbd.d/$guest.res && echo done"

	# self-verbose
	ssh $node "lvs /dev/thin/$guest && lvremove /dev/thin/$guest --yes"

	echo
done; unset node

