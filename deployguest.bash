#!/bin/bash
set -e

function usage {
	cat <<-EOF
	usage: $0 template.tar
	EOF
	exit 1
}

[[ -z $1 ]] && usage
archive=$1
template=${archive%%\.*}

cd /data/templates/

[[ -d $template/ ]] && echo $template/ already exists! && exit 1
[[ -f $template ]] && echo $template already exists BUT AS A FILE! && exit 1

du -k $archive
echo -n tar xSf $archive -C /data/guests/...
tar xSf $archive -C /data/guests/ && echo done
du -sk /data/guests/$template/

#cat <<EOF
#
#You should now run,
#
#	renameguest.bash $template NEW-NAME
#
#EOF

