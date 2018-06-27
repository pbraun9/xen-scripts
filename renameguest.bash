#!/bin/bash
set -e

function usage {
	cat <<-EOF
	usage: $0 guestX guestY
	EOF
	exit 1
}

[[ -z $2 ]] && usage

guestX=$1
guestY=$2

cd /data/guests/

[[ ! -d $guestX/ ]] && echo $guestX/ not found && exit 1
[[ -d $guestY/ ]] && echo $guestY/ already exists! && exit 1
[[ -f $guestY ]] && echo $guestY already exists BUT AS A FILE! && exit 1

echo -n mv $guestX/ $guestY/...
mv $guestX/ $guestY/ && echo done

echo -n updating the pathes and vif names...
cd $guestY/
[[ ! -f $guestX ]] && echo $guestX config not found && exit 1
sed -r "
s#name = \"$guestX\"#name = \"$guestY\"#;
s#/data/guests/$guestX/$guestX\.#/data/guests/$guestY/$guestY.#;
s#vifname=$guestX\.#vifname=$guestY.#
" $guestX > $guestY && rm -f $guestX && echo done
cd ../

#disk, img, qcow2, ext4, xfs, reiser4, swap, WHATEVER
echo renaming the files:
cd $guestY/
for f in $guestX.*; do
	echo -n mv $f ${f/$guestX/$guestY}...
	mv $f ${f/$guestX/$guestY} && echo done
done; unset f
cd ../

