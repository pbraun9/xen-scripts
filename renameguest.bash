#!/bin/bash
set -e

function usage {
	echo usage: ${0##*/} guestX guestY
	exit 1
}

[[ -z $2 ]] && usage

guestX=$1
guestY=$2

[[ ! -d $guestX/ ]] && echo could not find folder $guestX/ && exit 1
[[ -d $guestY/ ]] && echo $guestY/ already exists! && exit 1
[[ -f $guestY ]] && echo $guestY already exists BUT AS A FILE! && exit 1
[[ $guestX = $guestY ]] && echo guest names are the same && exit 1

echo -n renaming $guestX/ to $guestY/ ...
mv $guestX/ $guestY/ && echo done

echo -n updating the pathes and vif names...
[[ ! -f $guestY/$guestX ]] && echo $guestX config not found && exit 1
sed -r "s/$guestX/$guestY/" $guestY/$guestX > $guestY/$guestY \
	&& rm -f $guestY/$guestX && echo done

echo renaming additional files:
cd $guestY/
#disk, img, qcow2, ext4, xfs, reiser4, swap, WHATEVER
for f in $guestX.*; do
	mv $f ${f/$guestX/$guestY} && echo $f --\> ${f/$guestX/$guestY}
done && echo done; unset f
cd ../

