#!/bin/bash

# possible to run multiple times even if it fails
#set -e

[[ -z $1 ]] && echo "usage: ${0##*/} <guest name>" && exit 1
guest=$1
res=$guest

source /etc/dnc.conf
[[ -z $nodes ]] && echo \$nodes not defined && exit 1

for node in $nodes; do
	echo node $node

	echo resource $res down
	ssh $node "drbdadm down $res && echo done"

	echo -n remove resource $res ...
	ssh $node "rm -f /etc/drbd.d/$res.res && echo done"

	# self-verbose
	ssh $node "lvremove /dev/thin/$guest --yes"

	echo
done; unset node

