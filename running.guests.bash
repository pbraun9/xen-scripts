#!/bin/bash
#dsh -e -g xen "xl li | sed '1,2d' | awk '{print $1}'"
dsh -e -g xen "xl li | sed '1,2d'"
