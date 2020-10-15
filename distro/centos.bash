function setup-centos {
	echo PREPARING CENTOS

	echo -n hostname...
	echo $name > lala/etc/hostname && echo done || bomb

	echo -n hosts...
	cat > lala/etc/hosts <<-EOF && echo done || bomb
	127.0.0.1	localhost localhost.localdomain localhost4 localhost4.localdomain4
	::1		localhost localhost.localdomain localhost6 localhost6.localdomain6

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
	cp -pf lala/etc/resolv.conf lala/etc/resolv.conf.ip4

	echo -n network...
	cat > lala/etc/sysconfig/network <<-EOF && echo done || bomb
	NETWORKING=yes
	NOZEROCONF=no
	GATEWAY=$gw
	EOF

	echo -n ifcfg-eth0...
	cat > lala/etc/sysconfig/network-scripts/ifcfg-eth0 <<-EOF && echo done || bomb
	DEVICE=eth0
	IPADDR=$ip
	PREFIX=24
	ONBOOT=yes
	NM_CONTROLLED=no
	EOF

	# SILENT HOT FIX AGAINST TEMPLATE
	mv lala/etc/selinux/config lala/etc/selinux/config.tmp
	sed -r 's/SELINUX=permissive/SELINUX=disabled/' lala/etc/selinux/config.tmp > lala/etc/selinux/config
	rm -f lala/etc/selinux/config.tmp

	echo
}
