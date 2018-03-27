#!/bin/bash
set -e

# to be executed in folder /data/guests/

[[ -z $1 ]] && echo \$1 missing && exit 1

#removing the possible trailing slash
guest=${1%/}
tpl=/data/templates
archive=$tpl/$guest.`date +%s`.tar

[[ ! -d $guest/ ]] && echo $guest/ not found && exit 1

du -h $guest/
echo -n tar cSf $archive $guest/...
time tar cSf $archive $guest/ && echo done
du -h $archive

