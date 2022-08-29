#!/bin/bash
# no stop on error here
# we are supposed to be able to run this multiple times to clean-up vol and res on all the nodes
# need to remove the conf AFTER we removed volumes, as we use the conf as a hint

[[ ! -f /etc/dnc.conf ]] && echo /etc/dnc.conf not found && exit 1
. /etc/dnc.conf
[[ ! -n $hostprefix ]] && echo \$hostprefix not defined && exit 1

[[ -z $1 ]] && echo usage: "${0##*/} <minor>" && exit 1
minor=$1
res=dnc$minor

peers=`sed -rn '/^GROUP:xen/,/^$/p' /root/dsh.conf | sed '1d;$d' | grep -vE "^$HOSTNAME"`

# we need /etc/drbd.d/dnc1.res to know about the volumes
# TODO also create a script to find about existing volumes
[[ ! -f /etc/drbd.d/$res.res ]] && echo /etc/drbd.d/$res.res not found && exit 1

volpeerids=`sed -rn "/device minor $minor/,/connection-mesh/p" /etc/drbd.d/$res.res | grep -B2 '/dev/thin/dnc' | grep node-id | sed -r 's/[[:space:]]*node-id[[:space:]]*([[:digit:]]+);/\1/'`
volpeers=`for volpeerid in $volpeerids; do echo ${hostprefix}${volpeerid}; done; unset volpeerid`

echo REMOVING RESOURCE FROM NODES 
echo node is $HOSTNAME and peers are $peers
echo volumes are on $volpeers
echo

drbdadm down $res

# TODO check lv before remove
for volpeer in $volpeers; do
	echo -n removing volume on $volpeer...
	ssh $volpeer lvremove thin/$res --yes
done; unset volpeer

# TODO add locks in drbd.d/ for conflicting writes
echo -n removing resource conf...
# be it there or not
rm -f /etc/drbd.d/dnc$minor.res && echo done
for peer in $peers; do
        echo -n sync resource conf on $peer...
        rsync -az --delete /etc/drbd.d/ $peer:/etc/drbd.d/ && echo done
done; unset peer

