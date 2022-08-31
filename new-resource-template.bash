#!/bin/bash
set -e

[[ -z $4 ]] && echo "usage: ${0##*/} <node1> <node2> <drbd minor> <drbd resource name>" && exit 1

source /etc/dnc.conf

node1=$1
node2=$2
minor=$3
guest=$4

# tcp port goes as drbd minor for templates
# choose wisely (below 1024, not to interfere with guests)
(( port = minor ))

# size in GB (not GiB)
#size=25G
size=10G

# initial checks
[[ -f /etc/drbd.d/$guest.res ]] && echo /etc/drbd.d/$guest.res already exists && exit 1

echo
echo CREATE THIN VOLUME ON TWO NODES
echo

ssh $node1 lvcreate --virtualsize $size --thin -n $guest thin/pool
ssh $node2 lvcreate --virtualsize $size --thin -n $guest thin/pool
ssh $node1 lvs -o+discards thin/$guest
ssh $node2 lvs -o+discards thin/$guest

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

echo
echo INITIALIZE THE VOLUME
echo

echo create-md on $node1
ssh $node1 drbdadm create-md $guest
echo

echo create-md on $node2
ssh $node2 drbdadm create-md $guest
echo

for node in $nodes; do
	echo resource $guest up on $node
	ssh $node drbdadm up $guest
done; unset node
echo

# only once on one of the mirrors
echo drbd-fast-sync
sleep 3
ssh $node1 drbdadm new-current-uuid --clear-bitmap $guest
echo

drbdadm status $guest

