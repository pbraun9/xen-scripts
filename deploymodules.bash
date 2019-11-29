#!/bin/bash
set -e

function fix {
	cd /data/guests/$guest/
	fsck.ext4 $guest.ext4
	mkdir lala/
	mount -o loop,rw $guest.ext4 lala/

	mkdir -p lala/lib/modules/
	ls -alkF lala/lib/modules/
	rm -rf lala/lib/modules/*
	#for ball in `ls -1 /data/kernels/lib.modules.*.tar.gz`; do
	#        echo -n $ball...
	#        tar xzf $ball -C lala/lib/modules/ && echo done
	#done; unset ball
	tar xzf /data/kernels/lib.modules.$version.tar.gz -C lala/lib/modules/
	ls -alkF lala/lib/modules/

	cat lala/etc/modules
	echo tmem > lala/etc/modules

	umount lala/
	rmdir lala/
}

[[ -z $1 ]] && print guest? && exit 1
guest=$1

version=`file /data/kernels/vmlinuz | awk '{print $9}'`

fix

echo ALL DONE

