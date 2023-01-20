#!/bin/bash
set -e

[[ -z $2 ]] && echo "usage: ${0##*/} <template> <drbd minor> [resource name]" && exit 1

source /etc/dnc.conf
source /root/xen/newguest-functions.bash

tpl=$1
minor=$2
guest=$3

[[ -z $guest ]] && guest=dnc$minor

device=/dev/drbd$minor

case $tpl in
	debian*)
		node1=pmr1
		node2=pmr2
		butter=0
		;;
	slack*)
		node1=pmr2
		node2=pmr3
		butter=0
		;;
	netbsd*)
		node1=pmr3
		node2=pmr1
		butter=0
		;;
	*)
		bomb on which nodes to find snapshot origin for template $tpl?
		;;
esac

	#jammy)
	#	node1=pmr3
	#	node2=pmr1
	#	butter=0
	#	;;

# assuming decent guest id
# 0: guest configs on shared disk file-system
# 1 - 1023: templates and powerslack
# 1024 - 65534: for users
(( port = minor ))

# initial checks
[[ -f /etc/drbd.d/$guest.res ]] && echo /etc/drbd.d/$guest.res already exists && exit 1

echo
echo CREATE THIN SNAPSHOT FROM $tpl
echo

ssh $node1 ls /dev/thin/$guest 2>/dev/null && bomb thin/$guest already exists on $node1
ssh $node2 ls /dev/thin/$guest 2>/dev/null && bomb thin/$guest already exists on $node2

echo -n creating thin/$guest on $node1 ...
#dsh -e -w $node1 -s /root/xen/remote-check-lv.bash
ssh $node1 "lvcreate --snapshot -n $guest --setactivationskip n --ignoreactivationskip thin/$tpl >> /var/log/dnc.log 2>&1 && echo done"
	# --setautoactivation y

echo -n creating thin/$guest on $node2 ...
#dsh -e -w $node2 -s /root/xen/remote-check-lv.bash
ssh $node2 "lvcreate --snapshot -n $guest --setactivationskip n --ignoreactivationskip thin/$tpl >> /var/log/dnc.log 2>&1 && echo done"

echo

#ssh $node1 lvs -o+discards thin/$guest
#ssh $node2 lvs -o+discards thin/$guest

echo DRBD CONFIG AND SYNC
echo

# sanitize vars to avoid EOF in there
echo -n writing /etc/drbd.d/$guest.res ...
cat > /etc/drbd.d/$guest.res <<EOF
resource $guest {
	device minor $minor;
	meta-disk internal;
EOF

for node in $nodes; do
	id=`echo $node | sed -r "s/^$hostprefix//"`
	if [[ $node = $node1 || $node = $node2 ]]; then
		cat >> /etc/drbd.d/$guest.res <<EOF
	on $node {
		node-id   $id;
		address   10.3.3.$id:$port;
		disk      /dev/thin/$guest;
	}
EOF
	else
		cat >> /etc/drbd.d/$guest.res <<EOF
	on $node {
		node-id   $id;
		address   10.3.3.$id:$port;
		disk      none;
	}
EOF
	fi
done; unset node

cat >> /etc/drbd.d/$guest.res <<EOF && echo done
	connection-mesh {
		hosts $nodes;
	}
}
EOF

for node in $nodes; do
	if [[ $node != `hostname` ]]; then
		echo -n conf sync on $node ...
		rsync -a --delete /etc/drbd.d/ $node:/etc/drbd.d/ && echo done
	fi
done; unset node

# do not initialize volume otherwise we loose the snapshot template

for node in $nodes; do
	echo resource $guest up on $node
	ssh $node drbdadm up $guest
done; unset node
echo

echo waiting 3 seconds for the resources to connect...
sleep 3
echo
drbdadm status $guest

if (( butter == 1 )); then
	echo -n random butterfs uuid for $device file-system...
	btrfs check --readonly $device >/dev/null 2>&1 && echo y | btrfstune -u $device >/dev/null 2>&1 && echo done
	echo
fi

