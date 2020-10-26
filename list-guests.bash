#!/bin/bash

[[ -z $1 ]] && echo what user id? && exit 1
userid=$1

if [[ $userid = all ]]; then
	dsh -e -g xen "xl li | sed '1,2d'"
else
	dsh -e -g xen "xl li | sed '1,2d' | grep -E \"^dnc-$userid-\""
fi

