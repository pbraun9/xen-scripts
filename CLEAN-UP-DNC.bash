#!/bin/bash
# no -e as we need to proceed even if some strings are empty

#
# it's preferable to run those kinds of script node by node
#	so it's easier to handle
#	so we don't mess-up the lv vs. res correspondance
#
# this means we do not sync-drbd but gradually get rid of all the unused resource files before re-syncing
#

dnc_guests=`xl li | sed 1,2d | awk '{print $1}' | grep ^dnc`
# e.g. dnc1024
for guest in $dnc_guests; do
	echo -n destroy $guest ...
	xl destroy $guest && echo done
done; unset guest
echo

active_dnc_resources=`drbdadm status | grep ^dnc`
# e.g. dnc1024
for res in $active_dnc_resources; do
	# should be secondary already as the xen guest has been shut down
	echo -n drbd resource $res down ...
	drbdadm down $res && echo done
done; unset res
echo

# removing volumes step BEFORE the drbd resource file
lvm_dnc_vols=`ls -1 /dev/thin/ | grep ^dnc`
# e.g. dnc1024
for vol in $lvm_dnc_vols; do
	# self-verbose
        echo remove lvm volume thin/$vol :
        lvremove -f thin/$vol && echo done
done; unset vol
echo

defined_dnc_resources=`ls -1 /etc/drbd.d/ | grep ^dnc`
# e.g. dnc1024.res
for resfile in $defined_dnc_resources; do
	echo -n remove /etc/drbd.d/$resfile ...
	rm -f /etc/drbd.d/$resfile && echo done
done; unset resfile
echo

echo all done

