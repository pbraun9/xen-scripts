function setup-slackware {
	echo PREPARING SLACKWARE

	echo -n HOSTNAME...
	echo $name > lala/etc/HOSTNAME && echo done

	echo -n hosts...
	cat > lala/etc/hosts <<-EOF && echo done || bomb
	127.0.0.1	localhost
	::1		localhost

	$ip	$name
	$gw	gw
	$ip6	$name

	2001:bc8:401::3	dns1
	2001:bc8:1::16	dns2
	#62.210.16.6     dns1
	#62.210.16.7     dns2
	EOF

	echo -n resolv...
	cat > lala/etc/resolv.conf <<-EOF && echo done || bomb
	nameserver 2001:bc8:401::3
	nameserver 2001:bc8:1::16
	EOF

	# BEWARE OF ESCAPES HERE
	echo -n rc.inet1...
	cat > lala/etc/rc.d/rc.inet1 <<-EOF && echo done || bomb
	#!/bin/bash

	if [[ \$1 != stop && \$1 != down ]]; then
	 echo -n lo...
	 ifconfig lo up && echo done || echo FAIL

	 echo -n ipv4...
	 ifconfig eth0 $ip/24 up && echo done || echo FAIL

	 echo -n ipv4 default route...
	 route add default gw $gw && echo done || echo FAIL

	 echo -n ipv6...
	 ifconfig eth0 inet6 add $ip6/64 && echo done || echo FAIL
	fi
	EOF
	chmod +x lala/etc/rc.d/rc.inet1

	# SILENT HOTFIX AGAINST TEMPLATE
	rm -f lala/etc/motd

	echo
}
