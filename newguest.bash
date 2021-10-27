#!/bin/bash
set -e
echo

# /data/ is a shared among the nodes
for d in /data/drbd.d /data/guests /data/kernels /data/templates; do
	[[ ! -d $d/ ]] && echo create a shared-disk $d/ folder first && exit 1
done; unset d

[[ -z $2 ]] && echo -e usage: $0 GUEST-RESOURCE GUEST-HOSTNAME \\n && exit 1
guest=$1
name=$2

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

# even from here (possibly diskless)
echo -n making REISER4 file-system...
mkfs.reiser4 -y /dev/drbd/by-res/$guest/0 && echo done

# w/o the trailing slash for mount/grep to be happy
lala=/data/guests/$guest/lala
echo -n mounting into $lala/ ...
mount /dev/drbd/by-res/$guest/0 $lala/ && echo done

[[ -z `mount -t reiser4 | grep $lala` ]] && echo $lala/ is not mounted && exit 1
echo extracting slackware template
time nice tar xpf /data/templates/slack.tar --numeric-owner -C $lala/ && echo done

echo -n un-mounting $lala/
umount $lala/ && echo done

echo WILL NOW PROCEED WITH SYSPREP FOR HOSTNAME $name
echo ...

# resource should be fully up and running before trying to start the guest on it
#Error: Can't open /dev/drbd/by-res/dnc16/0. Read-only file system.
echo starting guest $guest
xl create /data/guests/$guest/$guest && echo GUEST $guest HAS BEEN STARTED

echo

