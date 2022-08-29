#!/bin/bash

should=`grep ^up$ /data/guests/*/state | cut -f4 -d/ | sort -V`
up=`dsh -e -g xen "xl list | sed '1,2d' | cut -f1 -d' '" | awk '{print $2}' | sort -V`

diff -bu <(echo "$should") <(echo "$up") | grep ^+ | sed 's/^+//'

