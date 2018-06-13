#!/bin/bash

[[ -z $1 ]] && echo missing guest name && exit 1

guest=$1
dump=/data/dumps/dump.`date +%s`.dumpcore

echo -n dumping $guest memory to $dump...
xl dump-core $guest $dump && echo done

