#!/bin/bash

repo=/data/media/slackware/142
slackmount=/tmp/slack
dummy=0

for set in a ap d f n; do
	for pkg in `grep :ADD$ $repo/$set/tagfile | cut -f1 -d:`; do
	        #egrep "^$repo/$set/$pkg-[[:alnum:]\._]+-[[:alnum:]_]+-[[:digit:]]+.txz$"
		pkgfix=`echo $pkg | sed 's/+/\\\+/g'`
	        pkgfile=`find $repo/ -type f | egrep "^$repo/$set/$pkgfix-[^-]+-[^-]+-[^-]+.txz$"`
	        [[ -z $pkgfile ]] && echo no txz archive found for $pkg && exit 1
		(( `echo $pkgfile | wc -l` != 1 )) && echo "too much results for $pkg:\n$pkgfile" && exit 1
		echo -n installpkg --root $slackmount $pkgfile...
		(( $dummy == 0 )) && installpkg --root $slackmount $pkgfile >/dev/null && echo done
		(( $dummy == 1 )) && echo \(dummy\)
		unset pkgfix pkgfile
	done; unset pkg
done; unset set

#was required when REC was used
#for pkg in ModemManager NetworkManager; do
#	echo -n ROOT=$slackmount removepkg $pkg...
#	ROOT=$slackmount removepkg $pkg >/dev/null && echo done
#done; unset pkg

#seems that gnupg1 is rather used, although marked as OPT in the tagfile
#installpkg --root /tmp/slack/ slackware64/n/gnupg2-2.0.30-x86_64-1.txz
#installpkg --root /tmp/slack/ slackware64/n/wget-1.18-x86_64-1.txz

#64 14.2 specific sorry
installpkg --root /tmp/slack/ $repo/n/openssh-7.2p2-x86_64-1.txz
installpkg --root /tmp/slack/ $repo/ap/slackpkg-2.82.1-noarch-3.txz

