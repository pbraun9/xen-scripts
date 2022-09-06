#!/bin/bash

export CLUSTER=/root/dsh.conf

dsh -e -g xen "xl list | sed '1,2d' | cut -f1 -d' '"

