#!/bin/bash

repo=/data/kernels/slackware142
slackmount=lala

# d f
for set in a ap; do
	for pkg in `grep :ADD$ $repo/$set/tagfile | cut -f1 -d:`; do
	        #egrep "^$repo/$set/$pkg-[[:alnum:]\._]+-[[:alnum:]_]+-[[:digit:]]+.txz$"
		pkgfix=`echo $pkg | sed 's/+/\\\+/g'`
	        pkgfile=`find $repo/ -type f | egrep "^$repo/$set/$pkgfix-[^-]+-[^-]+-[^-]+.txz$"`
	        [[ -z $pkgfile ]] && echo no txz archive found for $pkg && exit 1
		(( `echo $pkgfile | wc -l` != 1 )) \
			&& echo "too much results for $pkg:\n$pkgfile" && exit 1
	        echo -n installpkg --root $slackmount $pkgfile...
	        installpkg --root $slackmount $pkgfile >/dev/null && echo done
		unset pkgfix pkgfile
	done; unset pkg
done; unset set
echo ''

#REC
#remove ModemManager NetworkManager

