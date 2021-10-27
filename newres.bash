#!/bin/bash
set -e
echo

# /data/ is a shared among the nodes
for d in /data/drbd.d /data/guests /data/kernels /data/templates; do
	[[ ! -d $d/ ]] && echo create a shared-disk $d/ folder first && exit 1
done; unset d

[[ -z $3 ]] && echo -e usage: $0 NODE-ONE NODE-TWO DRBD-MINOR\\n && exit 1
one=$1
two=$2
minor=$3

others=`sed -rn '/^GROUP:xen/,/^$/p' /root/clusterit.conf | sed '1d;$d' | grep -vE "^$one|^$two"`

#lastminor=`grep -E '^[[:space:]]*device minor' /data/drbd.d/*.res | awk '{print $4}' | cut -f1 -d';' | sort -n | tail -1`
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
res=/data/drbd.d/$guest.res
[[ -f $res ]] && echo $res already exists && exit 1

echo THIN VOLUME CREATION
echo

echo creating thin volume $guest on $one
ssh $one lvcreate --virtualsize 10G --thin -n $guest thin/pool
echo

echo creating thin volume $guest one $two
ssh $two lvcreate --virtualsize 10G --thin -n $guest thin/pool
echo

echo DRBD RESOURCE SETUP
echo

# TODO improve ${other#slack} and use the initial RANDOM from above
nodeidone=${one#slack}
nodeidtwo=${two#slack}

#with device id $minor and port $port on nodes $one and $two...
echo -n creating $res with mirrors on $one $two ...
cat > $res <<EOF && echo done
        resource $guest {
                device minor $minor;
                meta-disk internal;
                on $one {
                        node-id   $nodeidone;
                        address   192.168.122.1$nodeidone:$minor;
                        disk      /dev/thin/$guest;
                }
                on $two {
                        node-id   $nodeidtwo;
                        address   192.168.122.1$nodeidtwo:$minor;
                        disk      /dev/thin/$guest;
                }
EOF
unset nodeidone nodeidtwo

echo -n adding $others to the resources ...
for other in $others; do
	nodeid=${other#slack}
	cat >> $res <<EOF && echo done
                on $other {
                        node-id   $nodeid;
                        address   192.168.122.1$nodeid:$minor;
                        disk      none;
                }
EOF
done; unset other nodeid

echo -n closing $res ...
cat >> $res <<EOF && echo done
                connection-mesh {
                        hosts slack1 slack2 slack3;
                }
        }
EOF
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

echo SLEEPING 1 SECOND AND STATUS
sleep 1
# resource is reachable locally even though it can be diskless
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

