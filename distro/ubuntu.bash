function setup-ubuntu {
	echo PREPARING UBUNTU

	echo -n hostname...
	echo $name > lala/etc/hostname && echo done || bomb

	echo -n hosts...
	cat > lala/etc/hosts <<-EOF && echo done || bomb
	127.0.0.1       localhost

	$ip	$name
	$gw	gw
	62.210.16.6	dns1
	62.210.16.7	dns2

	::1     localhost ip6-localhost ip6-loopback
	ff02::1 ip6-allnodes
	ff02::2 ip6-allrouters
	EOF

	echo -n netplan...
	cat > lala/etc/netplan/nethence.yaml <<-EOF && echo done || bomb
	network:
	  version: 2
	  renderer: networkd
	  ethernets:
	    eth0:
	      dhcp4: no
	      dhcp6: no
	      addresses:
	        - $ip/24
	      gateway4: ${ip%\.*}.$node
	      nameservers:
	        search: [nethence.com]
	        addresses: [62.210.16.6, 62.210.16.7]
	EOF

	echo
}
