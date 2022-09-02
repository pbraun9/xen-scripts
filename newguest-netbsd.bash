#!/bin/bash
set -e
echo

# TODO ifconfig.?

# this script assumes template $tpl is available (see the bsd/malabar-ffs guide)

[[ -z $1 ]] && echo usage: ${0##*/} GUEST-NAME && exit 1
guest=$1

source /root/xen/netbsd.conf
[[ -z $repo ]] && echo define \$repo && exit 1
[[ -z $name ]] && echo define \$name && exit 1
[[ -z $tpl ]] && echo define \$tpl && exit 1

short=${name%%\.*}

[[ ! -f $tpl ]] && echo could not find $tpl && exit 1

[[ ! -d /etc/drbd.d/ ]] && echo /etc/drbd.d/ not found && exit 1

[[ ! -f /etc/dnc.conf ]] && could not find /etc/dnc.conf && exit 1
source /etc/dnc.conf
[[ ! -n $pubkeys ]] && echo \$pubkeys not defined && exit 1

# /data/ is a shared among the nodes
for d in /data/guests /data/kernels /data/templates; do
	[[ ! -d $d/ ]] && echo create a shared-disk $d/ folder first && exit 1
done; unset d

echo NETBSD XEN GUEST CREATION
echo

# xenbr0 -- perimeter snat
#    br0 -- guests' vlans
echo -n writing guest config...
mkdir -p /data/guests/$guest/lala/
cat > /data/guests/$guest/$guest <<EOF && echo done
kernel = "$repo/netbsd-XEN3_DOMU.gz"
root = "xbd0a"
#extra = "-v -s"
name = "$guest"
memory = 512
vcpus = 3
disk = ['phy:/dev/drbd/by-res/$guest/0,xvda,w']
vif = [ 'bridge=guestbr0,vifname=$guest.0',
        'bridge=guestbr0,vifname=$guest.1']
#type = "pvh"
EOF

# possibly diskless
echo writing makefs-based image to resource $guest
nice dd if=$tpl of=/dev/drbd/by-res/$guest/0 bs=1M status=progress

cd /data/guests/$guest/
echo -n mounting into lala/ ...
mount -t ufs -o ufstype=44bsd /dev/drbd/by-res/$guest/0 lala/ && echo done
mount | grep ufs
echo

echo SYSPREP FOR HOSTNAME $name
echo

echo -n hostname $name ...
echo $short > lala/etc/myname && echo done

# we're lucky the dnc.conf evaluation works on $ip even though it was loaded before $minor got defined
echo tuning /etc/hosts
mv lala/etc/hosts lala/etc/hosts.dist
echo -e "::1\t\t\tlocalhost localhost." >> lala/etc/hosts
echo -e "127.0.0.1\t\tlocalhost localhost." > lala/etc/hosts
echo -e "${ip%/*}\t$short" >> lala/etc/hosts
[[ -n $gw ]] && echo -e "$gw\t\tgw" >> lala/etc/hosts
for dns in dns1 dns2 dns3; do
	[[ -n ${!dns} ]] && echo -e "${!dns}\t\t$dns" >> lala/etc/hosts
done; unset dns

for dns in dns1 dns2 dns3; do
	[[ -n ${!dns} ]] && echo -e "nameserver ${!dns}" >> lala/etc/resolv.conf
done; unset dns

echo -n adding pubkeys...
mkdir -p lala/root/.ssh/
cat > lala/root/.ssh/authorized_keys <<EOF && echo done
$pubkeys
EOF
chmod 700 lala/root/.ssh/
chmod 600 lala/root/.ssh/authorized_keys

# template should NOT have host keys within, erasing anyways
rm -f lala/etc/ssh/ssh_host_*

# we have better entropy on bare-metal
ssh-keygen -q -t dsa -f lala/etc/ssh/ssh_host_dsa_key -C root@$name -N ''
ssh-keygen -q -t rsa -f lala/etc/ssh/ssh_host_rsa_key -C root@$name -N ''
ssh-keygen -q -t ecdsa -f lala/etc/ssh/ssh_host_ecdsa_key -C root@$name -N ''
ssh-keygen -q -t ed25519 -f lala/etc/ssh/ssh_host_ed25519_key -C root@$name -N ''

echo -n un-mounting lala/ ...
umount lala/ && echo done
rmdir lala/

# we're using it right away
#drbdadm secondary $guest

# resource should be fully up and running before trying to start the guest on it
#Error: Can't open /dev/drbd/by-res/dnc16/0. Read-only file system.
echo starting guest $guest
xl create /data/guests/$guest/$guest && echo -e \\nGUEST $guest HAS BEEN STARTED
echo up > /data/guests/$guest/state
echo

