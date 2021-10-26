#!/bin/bash
set -e
echo

# /data/ is a shared among the nodes
for d in /data/drbd.d /data/guests /data/kernels /data/templates; do
	[[ ! -d $d/ ]] && echo create a shared-disk $d/ folder first && exit 1
done; unset d

[[ -z $1 ]] && echo -e usage: $0 GUEST-HOSTNAME \\n && exit 1
guestname=$1

lastminor=`grep -E '^[[:space:]]*device minor' /data/drbd.d/*.res | awk '{print $4}' | cut -f1 -d';' | \
	sort -n | tail -1`
echo lastminor is $lastminor
echo

(( minor = lastminor + 1 ))
(( minor > 9999 )) && echo sorry, we have reached the hard-coded limitation of 9999 DRBD device IDs && exit 1

(( port = 7000 + minor ))

# xen preliminaries...
guest=dnc$minor
[[ -d /data/guests/$guest/ ]] && echo /data/guests/$guest/ already exists && exit 1
[[ -f /data/guests/$guest/ ]] && echo /data/guests/$guest already exists AS FILE! && exit 1

# lvm preliminaries...

# drbd preliminaries...
mkdir -p /data/drbd.d/
res=/data/drbd.d/$guest.res
[[ -f $res ]] && echo $res already exists && exit 1

# storageleastbusy = ...
one=slack1
two=slack2
others=slack3

echo THIN VOLUME CREATION
echo

echo creating thin volume $guest on $one
ssh $one lvcreate --virtualsize 10G --thin -n $guest thin1/pool
echo

echo creating thin volume $guest one $two
ssh $two lvcreate --virtualsize 10G --thin -n $guest thin2/pool
echo

echo DRBD RESOURCE SETUP
echo

#with device id $minor and port $port on nodes $one and $two...
echo -n creating $res ...
cat > $res <<EOF && echo done
        resource $guest {
                device minor $minor;
                meta-disk internal;
                on slack1 {
                        node-id   1;
                        address   192.168.122.11:$port;
                        disk      /dev/thin1/$guest;
                }
                on slack2 {
                        node-id   2;
                        address   192.168.122.12:$port;
                        disk      /dev/thin2/$guest;
                }
                on slack3 {
                        node-id   3;
                        address   192.168.122.13:$port;
                        disk none;
                }
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

echo SLEEPING 1 SECOND
sleep 1
echo

for node in $one $two $others; do
	echo UP ON $node
	ssh $node drbdadm up $guest
done; unset node
echo

echo SLEEPING 5 SECONDS AND STATUS
sleep 5
drbdadm status $guest
echo

echo -n CLEAR-BITMAP ON $one ...
ssh $one drbdadm new-current-uuid --clear-bitmap $guest && echo DONE
echo

echo SLEEPING 5 SECONDS AND STATUS
sleep 5
drbdadm status $guest
echo

#echo refreshing resource manager on $others
#for other in $others; do
#	ssh $other drbdadm adjust-with-progress $guest
#done; unset other
#echo

# resource is reachable locally even though it can be diskless
#drbdadm status $guest
#echo

ssh $two lvs -o+discards thin2/$guest
echo

echo DEBUG -- all fine?
read -r

echo XEN GUEST CREATION
echo

mkdir -p /data/guests/$guest/lala/
domu=/data/guests/$guest/$guest
echo -n writing guest config $domu ...
cat > $domu <<EOF && echo done
kernel = "/data/kernels/vmlinuz"
root = "/dev/xvda1 ro console=hvc0 mitigations=off"
#extra = "init=/bin/bash"
name = "$guest"
memory = 7168
vcpus = 16
disk = ['phy:/dev/drbd/by-res/$guest/0,xvda1,w']
vif = [ 'bridge=xenbr0, vifname=$guest' ]
type = "pvh"
EOF
echo

# even from here (possibly diskless)
echo -n making REISER4 file-system...
mkfs.reiser4 -y /dev/drbd/by-res/$guest/0 && echo done
echo

# w/o the trailing slash for mount/grep to be happy
lala=/data/guests/$guest/lala
echo -n mounting into $lala/
mount /dev/drbd/by-res/$guest/0 $lala/ && echo done
echo

[[ -z `mount -t reiser4 | grep $lala` ]] && echo $lala/ is not mounted && exit 1
echo -n extracting slackware template...
time nice tar xpf /data/templates/slack.tar --numeric-owner -C $lala/ && echo done
echo

echo -n un-mounting $lala/
umount $lala/ && echo done
echo

#echo WILL NOW PROCEED WITH SYSPREP FOR HOSTNAME $guestname

# resource should be fully up and running before trying to start the guest on it
#Error: Can't open /dev/drbd/by-res/dnc16/0. Read-only file system.
echo starting guest $guest
xl create /data/guests/$guest/$guest && echo GUEST $guest HAS BEEN STARTED
echo

