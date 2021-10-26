#!/bin/bash
dsh -e -g xen "xl list | sed '1,2d' | cut -f1 -d' '"
