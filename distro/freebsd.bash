function setup-freebsd {
	echo PREPARING FREEBSD

	echo -n timezone...
	rm -f lala/etc/localtime
        #ln -s ../usr/share/zoneinfo/Europe/Moscow lala/etc/localtime
        ln -s ../usr/share/zoneinfo/Europe/Paris lala/etc/localtime

	echo -n rc.conf...
	cat > lala/etc/rc.conf <<EOF && echo done || bomb
ifconfig_xn0="inet $ip netmask 255.255.255.0 up"
defaultrouter="$gw"
hostname="$name.localdomain"
EOF

	echo -n hosts...
	cat > lala/etc/hosts <<EOF && echo done || bomb
::1                     localhost localhost.localdomain
127.0.0.1               localhost localhost.localdomain

# happy happy sendmail
$ip                     $name.localdomain $name
$gw                     gw
62.210.16.6             dns1
62.210.16.7             dns2
EOF

	echo -n resolv.conf...
	cat > lala/etc/resolv.conf <<EOF && echo done || bomb
nameserver 62.210.16.6
nameserver 62.210.16.7
EOF

	echo
}
