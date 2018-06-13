#!/bin/bash
set -e

# to be executed in folder /data/guests/

function usage {
	cat <<-EOF
	usage: $0 template.tar.gz
	EOF
	exit 1
}

[[ -z $1 ]] && usage
archive=$1
template=${archive%%\.*}

[[ -d $template/ ]] && echo $template/ already exists! && exit 1
[[ -f $template ]] && echo $template already exists BUT AS A FILE! && exit 1

du -h $archive
echo -n tar xzSf $archive -C /data/guests/...
time tar xzSf $archive -C /data/guests/ && echo done
du -h /data/guests/$template/

cat <<EOF

you should now run,

        cd /data/guests/
	renameguest.bash $template NEW-NAME

EOF

