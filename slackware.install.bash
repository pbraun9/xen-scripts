#!/bin/bash

repo=/tftpboot/slackware142/slackware64
slackmount=lala

[[ ! -d $repo ]] && echo $repo/ not found && exit 1

usage() {
	cat <<-EOF
usage: $0 <ADD|REC|OPT> [check]
EOF
	exit 1
}

[[ -z $1 ]] && usage
target=$1
[[ $target != ADD && $target != REC && $target != OPT ]] && usage

[[ $2 = check ]] && check=1

#[a-z]+ to get to packages/
installpkgname() {
	#egrep "^$repo/[a-z]+/$pkg-[[:alnum:]\._]+-[[:alnum:]_]+-[[:digit:]]+.txz$"
	pkgfix=`echo $pkg | sed 's/+/\\\+/g'`
	pkgfile=`find $repo/ -type f | egrep "^$repo/[a-z]+/$pkgfix-[^-]+-[^-]+-[^-]+.txz$"`
	[[ -z $pkgfile ]] && echo no txz archive found for $pkg && exit 1
	(( `echo "$pkgfile" | wc -l` != 1 )) \
		&& printf "too much results for $pkg:\n$pkgfile\n" && [[ -z $check ]] && exit 1
	if [[ -z $check ]]; then
		echo -n installpkg --root $slackmount $pkgfile...
		installpkg --root $slackmount $pkgfile >/dev/null && echo done
	fi
	unset pkgfix pkgfile
}

echo INSTALLING TAG --- $target --- FROM SETS A AP
for set in a ap; do
	[[ $target = ADD ]] && lalapkg=`grep :ADD$ $repo/$set/tagfile | cut -f1 -d:`
	[[ $target = REC ]] && lalapkg=`egrep ':ADD$|:REC$' $repo/$set/tagfile | cut -f1 -d:`
	[[ $target = OPT ]] && lalapkg=`egrep ':ADD$|:REC$|:OPT$' $repo/$set/tagfile | cut -f1 -d:`
	for pkg in $lalapkg; do
		installpkgname
	done; unset pkg
	unset lalapkg
done; unset set
echo ''

#gnutls
echo INTSALLING FEW PACKAGES FROM SET N
for pkg in \
	iputils \
	net-tools \
	network-scripts \
	openssh \
	; do
	installpkgname
done; unset pkg
echo ''

echo INTSALLING ADD+SLACKPKG
for pkg in \
	which \
	dialog \
	slackpkg \
        ncurses \
        gnupg \
        wget \
        libunistring \
	; do
	installpkgname
done; unset pkg
echo ''

echo INTSALLING ADDITIONAL PACKAGES
for pkg in \
	curl \
	lynx \
	lftp \
	; do
	installpkgname
done; unset pkg
echo ''

echo INTSALLING SNE PACKAGES
for pkg in \
        jfsutils \
	iptables \
        ; do
        installpkgname
done; unset pkg
echo ''

#echo SBOPKG
#	bonnie++ \

