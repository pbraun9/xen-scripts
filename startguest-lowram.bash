#!/bin/bash
set -e

function support {
	cat <<EOF

	Cluster state not optimal - node $node is under maintenance

	Please try again in 15 minutes or reach out to <support@angrycow.ru>.

EOF
	exit 1
}
# Reach out to support team for feedback, feature requests and bug reports

export CLUSTER=/root/dsh.conf

[[ -z $1 ]] && echo "${0##*/} <GUEST-NAME>" && exit 1
guest=$1

source /etc/dnc.conf
[[ -z $hostprefix ]] && echo define hostprefix && exit 1

alive=`dsh -e -g xen "xl list | grep -E \"^$guest[[:space:]]+\"" | cut -f1 -d:`
[[ -n $alive ]] && echo $guest already lives on $alive && exit 1

# check cluster state is optimal
for node in $nodes; do
	ssh $node "[[ -d /data/guesta/ ]]" || support
done; unset node

guestpath=/data/guests/$guest
conf=$guestpath/$guest
[[ ! -f $conf ]] && echo $conf cannot be found && exit 1

freeram=`dsh -e -g pmr "xl info | grep ^free_memory" | sort -k 3 | tail -1`
free=`echo $freeram | awk '{print $NF}'`
node=`echo $freeram | cut -f1 -d:`
echo "least used RAM node is $node ($free M free)"

ssh $node "xl create $conf"
echo -e \\nGUEST $guest HAS BEEN STARTED ON NODE $node\\n
echo up > $guestpath/state

