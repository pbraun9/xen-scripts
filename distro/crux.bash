function setup-crux {
	echo PREPARING CRUX

	echo -n hostname...
	mv -f lala/etc/rc.conf lala/etc/rc.conf.tmp
	sed -r "s/HOSTNAME=.*/HOSTNAME=$name/" lala/etc/rc.conf.tmp > lala/etc/rc.conf && rm -f lala/etc/rc.conf.tmp && echo done || bomb

	echo -n hosts...
	cat > lala/etc/hosts <<-EOF && echo done || bomb
	127.0.0.1       localhost

	$ip	$name
	$gw	gw

	::1            ip6-localhost   ip6-loopback
	fe00::0        ip6-localnet
	ff00::0        ip6-mcastprefix
	ff02::1        ip6-allnodes
	ff02::2        ip6-allrouters
	ff02::3        ip6-allhosts
	EOF

	echo -n rc.d/net...
	mv -f lala/etc/rc.d/net lala/etc/rc.d/net.tmp
	sed -r "s/ADDR=.*/ADDR=$ip/;
		s/GW=.*/GW=$gw/;
		" lala/etc/rc.d/net.tmp > lala/etc/rc.d/net && rm -f lala/etc/rc.d/net.tmp && echo done || bomb
	chmod +x lala/etc/rc.d/net

	#resolv.conf already fine from template

	echo
}
