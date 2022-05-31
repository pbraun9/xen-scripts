#!/bin/bash
set -e

[[ -z $2 ]] && echo "usage: ${0##*/} <guest name> <ip suffix>" && exit 1

guest=$1
suffix=$2
(( port = 7000 + suffix ))

# size in GB (not GiB)
#size=25G
size=10G

cat <<EOF
# CREATE THIN VOLUME ON TWO NODES E.G. NODES 2 AND 3
lvcreate --virtualsize $size --thin -n $guest thin/pool

EOF

cat <<EOF
# ADD THIS TO DRBD CONFIG AND SYNC
vi /etc/drbd.d/$guest.res

resource $guest {
	device minor $suffix;
	meta-disk internal;
	on pmr1 {
		node-id   1;
		address   10.3.3.1:$port;
		disk      none;
	}
	on pmr2 {
		node-id   2;
		address   10.3.3.2:$port;
		disk      /dev/thin/$guest;
	}
	on pmr3 {
		node-id   3;
		address   10.3.3.3:$port;
		disk      /dev/thin/$guest;
	}
	connection-mesh {
		hosts pmr1 pmr2 pmr3;
	}
}

rsync -av --delete /etc/drbd.d/ pmr2:/etc/drbd.d/
rsync -av --delete /etc/drbd.d/ pmr3:/etc/drbd.d/
EOF

cat <<EOF
# ALSO INITIALIZE THE VOLUME

# mirror nodes
drbdadm create-md $guest
drbdadm up $guest

# diskless nodes
drbdadm up $guest

# only once on one of the mirrors
drbdadm new-current-uuid --clear-bitmap $guest
drbdadm status $guest
ssh pmr2 lvs -o+discards thin/$guest
ssh pmr3 lvs -o+discards thin/$guest

EOF

