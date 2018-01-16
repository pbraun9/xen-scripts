#!/bin/bash
set -e

# to be executed in folder /data/guests/

[[ -z $1 ]] && echo \$1 missing && exit 1

#removing the possible trailing slash
guest=${1%/}
archive=$guest.`date +%s`.tar.gz
#archive=$guest.`date +%s`.tar

[[ ! -d $guest/ ]] && echo $guest/ not found && exit 1

du -h $guest/
echo -n tar czSf $archive $guest/...
time tar czSf $archive $guest/ && echo done
#time tar cSf $archive $guest/ && echo done
du -h $archive
