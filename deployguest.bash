#!/bin/bash
set -e

[[ -z $1 ]] && echo what template? && exit 1

archive=$1
template=${archive%%\.*}

[[ -d $template/ ]] && echo $template/ already exists! && exit 1
[[ -f $template ]] && echo $template already exists BUT AS A FILE! && exit 1

du -h /data/templates/$archive
echo -n tar xSf /data/templates/$archive ...
tar xSf /data/templates/$archive && echo done
du -sh $template/

#cat <<EOF
#
#You should now run,
#
#	renameguest.bash $template NEW-NAME
#
#EOF

