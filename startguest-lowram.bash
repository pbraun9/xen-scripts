#!/bin/bash
set -e

# memory allocated to guests at boot-time
memory=1024

function bomb {
	echo Error: $@
	exit 1
}

function is_maintenance {
	cat <<EOF

	Cluster state not optimal - node $node is under maintenance

	Please try again in 15 minutes

EOF
	exit 1
}

export CLUSTER=/root/dsh.conf

[[ -z $1 ]] && echo "${0##*/} <GUEST-NAME>" && exit 1
guest=$1

source /etc/dnc.conf
[[ -z $hostprefix ]] && echo define hostprefix && exit 1

alive=`dsh -e -g xen "xl list | grep -E \"^$guest[[:space:]]+\"" | cut -f1 -d:`
[[ -n $alive ]] && echo $guest already lives on $alive && exit 1

# check cluster state is optimal
for node in $nodes; do
	ssh $node ls -1d /data/templates/ >/dev/null 2>&1 || is_maintenance
done; unset node

guestpath=/data/guests/$guest
conf=$guestpath/$guest
[[ ! -f $conf ]] && echo $conf cannot be found && exit 1

# available memory left hence we look for the greatest amount
freeram=`dsh -e -g pmr "xl info | grep ^free_memory" | sort -V -k3 -t: | tail -1`
free=`echo $freeram | awk '{print $NF}'`
node=`echo $freeram | cut -f1 -d:`
echo "least used RAM node is $node ($free M free)"

[[ -z $free ]] && bomb failed to define \$free
[[ -z $node ]] && bomb failed to define \$node

(( free < memory )) && bomb not enough memory available on any node of the cluster \($free on $node\)

ssh $node "xl create $conf"
echo -e \\nGUEST $guest HAS BEEN STARTED ON NODE $node\\n
echo up > $guestpath/state

