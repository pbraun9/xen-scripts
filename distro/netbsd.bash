function setup-netbsd {
	echo PREPARING NETBSD

	echo -n hostname...
	echo $name > lala/etc/myname && echo done

	echo -n hosts...
	cat > lala/etc/hosts <<-EOF && echo done || bomb
	::1             localhost localhost.
	127.0.0.1       localhost localhost.

	$ip	$name
	$gw	gw
	EOF

	echo -n xennet0...
	echo inet $ip/24 up > lala/etc/ifconfig.xennet0 && echo done

	echo -n gateway...
	echo $gw > lala/etc/mygate && echo done

	echo -n resolv...
	cat > lala/etc/resolv.conf <<-EOF && echo done
	search nethence.com
	nameserver 62.210.16.6
	nameserver 62.210.16.7
	EOF

	echo HOT FIX FOR SSHD...
	echo sshd=yes >> lala/etc/rc.conf && echo DONE

	echo
}
