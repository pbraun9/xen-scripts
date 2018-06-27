#!/bin/bash
set -e

[[ -z $1 ]] && echo what guest? && exit 1

cd /data/guests/

#removing the possible trailing slash
guest=${1%/}
tpl=/data/templates
archive=$tpl/$guest.`date +%s`.tar

[[ ! -d $guest/ ]] && echo $guest/ not found && exit 1

du -sk $guest/
echo -n tar cSf $archive $guest/...
time tar cSf $archive $guest/ && echo done
du -k $archive

