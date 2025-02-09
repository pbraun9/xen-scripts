#!/bin/bash
set -e

[[ -z $2 ]] && echo usage: ${0##*/} guestX guestY && exit 1
guestX=$1
guestY=$2

cd /data/guests/

[[ $guestX = $guestY ]] && echo guest names are the same && exit 1

[[ ! -d $guestX/ ]] && echo could not find folder $guestX/ && exit 1
[[ ! -f $guestX/$guestX ]] && echo could not find $guestX config $guestX/$guestX && exit 1
[[ -f $guestX ]] && echo $guestY conf exists as a file?! && exit 1

[[ -d $guestY/ ]] && echo $guestY/ already exists! && exit 1
[[ -f $guestY ]] && echo $guestY conf already exists but as a file?! && exit 1

echo -n cloning $guestX/ to $guestY/ ...
cp -R --sparse=always $guestX/ $guestY/ && echo done

cd $guestY/

echo -n writing xen guest config file $guestY ...
sed -r "s/$guestX/$guestY/" $guestX > $guestY && echo done

echo -n removing previous xen guest config file ...
rm -f $guestX && echo done

# disk, img, qcow2, ext4, xfs, reiser4, swap, WHATEVER
for f in $guestX.*; do
	echo -n renaming $f --\> ${f/$guestX/$guestY} ...
	mv -i $f ${f/$guestX/$guestY} && echo done
done; unset f

cd ../

