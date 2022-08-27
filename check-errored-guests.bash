#!/bin/bash

should=`grep ^up$ /data/guests/*/state | cut -f4 -d/ | sort -n`
up=`dsh -e -g xen "xl list | sed '1,2d' | cut -f1 -d' '" | awk '{print $2}' | sort -n`

echo should is $should
echo and up is $up

diff -bu <(echo "$should") <(echo "$up")

