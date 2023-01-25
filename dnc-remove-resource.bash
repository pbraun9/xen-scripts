#!/bin/bash

# possible to run multiple times even if it fails
#set -e

[[ -z $1 ]] && echo "usage: ${0##*/} <drbd resource name>" && exit 1
guest=$1

source /etc/dnc.conf
source /usr/local/lib/dnclib.bash

[[ -z $nodes ]] && echo \$nodes not defined && exit 1

if [[ -n `mount | grep guests/$guest/` ]]; then
	umount /dev/drbd/by-res/$guest/0
	sleep 1
	[[ -n `mount | grep guests/$guest/` ]] && bomb $guest is still mounted somewhere
fi

# self-verbose
dnc-shutdown-guest.bash $guest

echo -n clean-up guest config...
rm -rf /data/guests/$guest/ && echo done

for node in $nodes; do
	echo -n down resource $guest on $node ...
	ssh $node "drbdadm down $guest && echo done"

	echo -n remove drbd resource $guest on $node ...
	ssh $node "rm -f /etc/drbd.d/$guest.res && echo done"

	echo remove logical volume thin/$guest on $node
	# self-verbose
	ssh $node "lvs thin/$guest && lvremove thin/$guest --yes"

	echo
done; unset node

