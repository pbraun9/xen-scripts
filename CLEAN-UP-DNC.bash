#!/bin/bash
set -e

#
# it's preferable to run those kinds of script node by node
#	so it's easier to handle
#	so we don't mess-up the lv vs. res correspondance
#
# this means we do not sync-drbd but gradually get rid of all the unused resource files before re-syncing
#

dnc_guests=`xl li | sed 1,2d | awk '{print $1}' | grep ^dnc`
# e.g. dnc1024
for dnc_guest in $dnc_guests; do
	echo -n destroy $guest ...
	xl destroy $guest && echo done
done; unset dnc_guest
echo

active_dnc_resources=`drbdadm status | grep ^dnc`
# e.g. dnc1024
for active_dnc_resource in $active_dnc_resources; do
	# should be secondary already as the xen guest has been shut down
	echo -n drbd resource $res down ...
	drbdadm down $res && echo done
done; unset active_dnc_resource
echo

# removing volumes step BEFORE the drbd resource file
lvm_dnc_vols=`ls -1 /dev/thin/ | grep ^dnc`
# e.g. dnc1024
for lvm_dnc_vol in $lvm_dnc_vols; do
	# self-verbose
        echo remove lvm volume thin/$res :
        lvremove -f thin/$res && echo done
done; unset lvm_dnc_vol
echo

#defined_dnc_resources=`ls -1 /etc/drbd.d/ | grep ^dnc`
# e.g. dnc1024.res
#for defined_dnc_resource in $defined_dnc_resources do
#	echo -n remove /etc/drbd.d/$res.res ...
#	rm -f /etc/drbd.d/$res.res && echo done
#done; unset defined_dnc_resource

echo all done

