#!/bin/bash
set -e

[[ -z $3 ]] && echo "usage: ${0##*/} <template> <drbd minor> <drbd resource name>" && exit 1

source /etc/dnc.conf

tpl=$1
minor=$2
guest=$3

device=/dev/drbd$minor

[[ ! -b /dev/thin/$tpl ]] && echo there is no LV matching template $tpl && exit 1

case $tpl in
	slack150)
		node1=pmr1
		node2=pmr2
		;;
	bullseye)
		node1=pmr2
		node2=pmr3
		;;
	jammy)
		node1=pmr3
		node2=pmr1
		;;
	*)
		echo donno how to distribute snapshot from template $tpl
		exit 1
		;;
esac

# starts at tcp port 1024
(( port = 1023 + minor ))

# initial checks
[[ -f /etc/drbd.d/$guest.res ]] && echo /etc/drbd.d/$guest.res already exists && exit 1

echo
echo CREATE THIN SNAPSHOT FROM $tpl
echo

ssh $node1 "lvcreate --snapshot -n $guest \
	--setactivationskip n --ignoreactivationskip \
	thin/$tpl >> /var/log/lvm.log 2>&1 && echo thin/$tpl up on $node1"
ssh $node2 "lvcreate --snapshot -n $guest \
	--setactivationskip n --ignoreactivationskip \
	thin/$tpl >> /var/log/lvm.log 2>&1 && echo thin/$tpl up on $node2"
	# --setautoactivation y
#ssh $node1 lvs -o+discards thin/$guest
#ssh $node2 lvs -o+discards thin/$guest
echo

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

echo -n random butterfs uuid for $device file-system...
btrfs check --readonly $device >/dev/null 2>&1 && echo y | btrfstune -u $device >/dev/null 2>&1 && echo done
echo

