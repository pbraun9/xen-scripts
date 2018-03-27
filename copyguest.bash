#!/bin/bash
set -e

# to be executed in folder /data/guests/

function usage {
	cat <<-EOF
	usage: $0 guestX guestY
	EOF
	exit 1
}

function newdisk {
	for disk in *.$1; do
	        newdisk=`echo $disk | sed -r "s#$guestX#$guestY#g"`
	        echo -n renaming $disk to $newdisk...
	        mv $disk $newdisk && echo done
		unset newdisk
	done; unset disk
}

[[ -z $1 ]] && usage
[[ -z $2 ]] && usage

guestX=$1
guestY=$2

[[ ! -d $guestX/ ]] && echo $guestX/ not found && exit 1
[[ -d $guestY/ ]] && echo $guestY/ already exists! && exit 1
[[ -f $guestY ]] && echo $guestY already exists BUT AS A FILE! && exit 1

#du -h $guestX/
echo -n copying $guestX/ to $guestY/...
cp -R $guestX/ $guestY/ && echo done
#du -h $guestY/

echo -n updating the pathes and vif names...
cd $guestY/
[[ ! -f $guestX ]] && echo $guestX not found && exit 1
sed -r "
s#name = \"$guestX\"#name = \"$guestY\"#;
s#/data/guests/$guestX/$guestX\.#/data/guests/$guestY/$guestY.#;
s#vifname=$guestX\.#vifname=$guestY.#
" $guestX > $guestY && rm -f $guestX && echo done

echo renaming the disks, images and swap files:
newdisk disk
newdisk img
newdisk swap

