#!/bin/bash

dsh -e -g xen pgrep -a keepalive
echo

#dsh -e -g xen tail -2 /var/tmp/keepalive.log
dsh -e -g xen ip addr show xenbr0 | grep \\.157
dsh -e -g xen ip addr show guestbr0 | grep \\.254
echo

dsh -e -g xen pgrep -a conntrack
echo

echo all done
echo

