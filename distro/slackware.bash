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
	62.210.16.6     dns1
	62.210.16.7     dns2
	EOF

	echo -n resolv...
	cat > lala/etc/resolv.conf <<-EOF && echo done || bomb
	search nethence.com
	nameserver 62.210.16.6
	nameserver 62.210.16.7
	EOF

	# BEWARE OF ESCAPES HERE
	echo -n rc.inet1...
	cat > lala/etc/rc.d/rc.inet1 <<-EOF && echo done || bomb
	#!/bin/bash

	if [[ \$1 != stop && \$1 != down ]]; then
	 echo -n lo...
	 ifconfig lo up && echo done || echo FAIL

	 echo -n eth0...
	 ifconfig eth0 $ip/24 up && echo done || echo FAIL

	 echo -n default route...
	 route add default gw $gw && echo done || echo FAIL
	fi
	EOF
	chmod +x lala/etc/rc.d/rc.inet1

	# SILENT HOTFIX AGAINST TEMPLATE
	rm -f lala/etc/motd

	echo
}
