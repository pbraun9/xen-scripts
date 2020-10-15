function setup-sabotage {
	echo PREPARING SABOTAGE

	echo -n hostname...
	echo $name > lala/etc/hostname && echo done || bomb

	echo -n hosts...
	cat > lala/etc/hosts <<-EOF && echo done || bomb
	127.0.0.1       localhost.localdomain   localhost
	::1             localhost.localdomain   localhost

	$ip	$name
	$gw	gw
	62.210.16.6     dns1
	62.210.16.7     dns2
	EOF

	echo -n rc.local network configuration...
	mv -f lala/etc/rc.local lala/etc/rc.local.tmp
	#do_static_ip already set to true into template
	sed -r "s/[[:space:]]ip=.*/ip=$ip/" lala/etc/rc.local.tmp > lala/etc/rc.local && rm -f lala/etc/rc.local.tmp && echo done
	chmod +x lala/etc/rc.local

	echo -n resolv...
	cat > lala/etc/resolv.conf <<-EOF && echo done
	search nethence.com
	nameserver 62.210.16.6
	nameserver 62.210.16.7
	EOF

	echo
}
