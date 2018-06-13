#!/bin/bash

echo MEMORY
dsh -e -g cluster "free -m | grep ^Mem"
echo ''

echo VERSIONS
dsh -e -g xen "xl dmesg | head | grep 'Xen version' | sed 's/(gcc .*$//'"
echo ''

