function setup-debian {
	echo PREPARING DEBIAN

	echo -n hostname...
	echo $name > lala/etc/hostname && echo done || bomb

	echo -n hosts...
	cat > lala/etc/hosts <<-EOF && echo done || bomb
	127.0.0.1 localhost

	$ip	$name
	$gw	gw

	::1 ip6-localhost ip6-loopback
	fe00::0 ip6-localnet
	ff00::0 ip6-mcastprefix
	ff02::1 ip6-allnodes
	ff02::2 ip6-allrouters
	ff02::3 ip6-allhosts
	EOF

	echo -n interfaces...
	#using space not tabs for indentation coz we use -EOF here
	cat > lala/etc/network/interfaces <<-EOF && echo done || bomb
	auto lo
	iface lo inet loopback

	auto eth0
	iface eth0 inet static
	 address $ip/24
	 gateway ${ip%\.*}.1
	 dns-search nethence.com
	 dns-nameservers 62.210.16.6 62.210.16.7
	EOF
		#dns-nameservers 208.67.222.222 208.67.220.220

	#echo -n resolv...
	#getting rid of resolved symlink
	#mv lala/etc/resolv.conf lala/etc/resolv.conf.dist
	#cat > lala/etc/resolv.conf <<-EOF && echo done
	#search nethence.com
	#nameserver 208.67.222.222
	#nameserver 208.67.220.220
	#EOF

	#echo NEXT ROUND TEMPLATE lala/etc/systemd/resolved.conf...
	#cat >> lala/etc/systemd/resolved.conf <<-EOF
	#Cache=no
	#DNSStubListener=no
	#EOF

	echo
}
