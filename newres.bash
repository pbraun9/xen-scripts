#!/bin/bash
set -e

[[ ! -d /etc/drbd.d/ ]] && echo /etc/drbd.d/ not found && exit 1

[[ ! -f /etc/dnc.conf ]] && cannot find /etc/dnc.conf && exit 1
source /etc/dnc.conf
[[ ! -n $network ]] && echo \$network not defined && exit 1
netprefix=`echo $network | sed -r 's/^([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+)\..*/\1/'`

# /data/ is a shared among the nodes
for d in /data/guests /data/kernels /data/templates; do
	[[ ! -d $d/ ]] && echo create a shared-disk $d/ folder first && exit 1
done; unset d

[[ -z $3 ]] && echo -e usage: ${0##*/} NODE-ONE NODE-TWO DRBD-MINOR\\n && exit 1
one=$1
two=$2
minor=$3

others=`sed -rn '/^GROUP:xen/,/^$/p' /root/dsh.conf | sed '1d;$d' | grep -vE "^$one|^$two"`
peers=`sed -rn '/^GROUP:xen/,/^$/p' /root/dsh.conf | sed '1d;$d' | grep -vE "^$HOSTNAME"`

echo CREATING RESOURCE FOR NODES $one $two $others
echo node is $HOSTNAME and peers are $peers
echo

#lastminor=`grep -E '^[[:space:]]*device minor' /etc/drbd.d/*.res | awk '{print $4}' | cut -f1 -d';' | sort -n | tail -1`
#echo lastminor is $lastminor
#echo

#(( minor = lastminor + 1 ))
#(( minor > 9999 )) && echo sorry, we have reached the hard-coded limitation of 9999 DRBD device IDs && exit 1
(( port = minor ))

# xen preliminaries...
guest=dnc${minor}
[[ -d /data/guests/$guest/ ]] && echo /data/guests/$guest/ already exists && exit 1
[[ -f /data/guests/$guest/ ]] && echo /data/guests/$guest already exists AS FILE! && exit 1

# lvm preliminaries...

# drbd preliminaries...
res=/etc/drbd.d/$guest.res
[[ -f $res ]] && echo $res already exists && exit 1


#
# THIN VOLUME CREATION
#
echo creating thin volume $guest on $one
ssh $one lvcreate --virtualsize 10G --thin -n $guest thin/pool
echo

echo creating thin volume $guest one $two
ssh $two lvcreate --virtualsize 10G --thin -n $guest thin/pool
echo


#
# DRBD RESOURCE SETUP
#
# TODO improve ${other#slack} and use the initial RANDOM from above
nodeidone=${one##*[a-z]}
nodeidtwo=${two##*[a-z]}

# device id $minor and port $port on nodes $one and $two
echo -n creating $res with mirrors on $one $two...
cat > $res <<EOF
        resource $guest {
                device minor $minor;
                meta-disk internal;
                on $one {
                        node-id   $nodeidone;
                        address   $netprefix.$nodeidone:$minor;
                        disk      /dev/thin/$guest;
                }
                on $two {
                        node-id   $nodeidtwo;
                        address   $netprefix.$nodeidtwo:$minor;
                        disk      /dev/thin/$guest;
                }
EOF
unset nodeidone nodeidtwo

for other in $others; do
	nodeid=${other##*[a-z]}
	cat >> $res <<EOF
                on $other {
                        node-id   $nodeid;
                        address   $netprefix.$nodeid:$minor;
                        disk      none;
                }
EOF
done; unset other nodeid

cat >> $res <<EOF && echo done
                connection-mesh {
                        hosts $one $two $others;
                }
        }
EOF

#
# SYNC RESOURCE CONFIG
#
for peer in $peers; do
	echo -n sync resource conf on $peer...
	rsync -az --delete /etc/drbd.d/ $peer:/etc/drbd.d/ && echo done
done; unset peer
echo

echo CREATE-MD ON NODE $one
ssh $one drbdadm create-md $guest
echo

echo CREATE-MD ON NODE $two
ssh $two drbdadm create-md $guest
echo

for node in $one $two $others; do
	echo UP ON $node
	ssh $node drbdadm up $guest
done; unset node
echo

echo SLEEPING 1 SECOND
sleep 1
echo

echo -n CLEAR-BITMAP ON $one ...
ssh $one drbdadm new-current-uuid --clear-bitmap $guest && echo DONE
echo

# resource is reachable locally even though it can be diskless
echo SLEEPING 1 SECOND AND STATUS
echo
sleep 1
drbdadm status $guest
echo

#echo refreshing resource manager on $others
#for other in $others; do
#	ssh $other drbdadm adjust-with-progress $guest
#done; unset other
#echo

#ssh $two lvs -o+discards thin/$guest
#echo

echo DRBD RESOURCE $guest IS READY
echo

