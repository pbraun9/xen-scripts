#!/bin/bash
set -e

# TODO ifconfig.?

# STABLE vs. CURRENT
#kernel=/data/kernels/netbsd9/netbsd-XEN3_DOMU.gz
kernel=/data/kernels/netbsd-current/netbsd-XEN3_DOMU.gz

# no need for $tpl here since we already defined that while cloning the origin snapshot
[[ -z $1 ]] && echo usage: "${0##*/} <drbd minor> [guest hostname]" && exit 1
minor=$1
[[ -n $2 ]] && guest=$2 || guest=dnc$minor

guestid=$minor
name=$guest
short=${name%%\.*}

source /etc/dnc.conf
source /root/xen/newguest-functions.bash
source /root/xen/newguest-include-checks.bash

# gw and friends got sourced by dnc.conf
# but guest ip gets eveluated by dec2ip function
dec2ip

[[ -z $kernel ]] && bomb missing \$kernel
[[ -z $ip ]] && bomb missing \$ip
[[ -z $gw ]] && bomb missing \$gw

echo
echo SYSPREP FOR HOSTNAME $name
echo

echo -n mounting $guest FFS read-write into /data/guests/$guest/lala/ ...
[[ -n `mount | grep guests/$guest/` ]] && bomb $guest already mounted
mkdir -p /data/guests/$guest/lala/
cd /data/guests/$guest/
mount -t ufs -o rw,ufstype=44bsd /dev/drbd/by-res/$guest/0 lala/ && echo done
mount | grep ufs
echo

echo -n hostname $name ...
echo $short > lala/etc/myname && echo done

# we're lucky the dnc.conf evaluation works on $ip even though it was loaded before $minor got defined
echo -n static name resolution...
[[ ! -f lala/etc/hosts.dist ]] && mv lala/etc/hosts lala/etc/hosts.dist
cat > lala/etc/hosts <<EOF && echo done
::1                     localhost localhost.
127.0.0.1               localhost localhost.

$ip		$short
$gw		gw
$dns1		dns1
$dns2		dns2

EOF

echo -n xennet0 ...
echo inet $ip/16 up > lala/etc/ifconfig.xennet0 && echo done

echo -n gw...
echo $gw > lala/etc/mygate && echo done

# erase anything previously define in the template
echo -n dynanic name resolution...
cat > lala/etc/resolv.conf <<EOF && echo done
nameserver $dns1
nameserver $dns2

EOF

# THIS BREAKS THE FS
# kernel: ufs: error (device drbd1027): ufs_new_inode: cylinder group 0 corrupted - error in inode bitmap
# kernel: ufs: ufs_fill_super(): fs is bad
#mkdir -p lala/root/.ssh/

# erase previously defined pubkeys from template
echo -n pubkeys...
[[ ! -d lala/root/.ssh/ ]] && bomb could not find folder lala/root/.ssh/
cat > lala/root/.ssh/authorized_keys <<EOF && echo done
$pubkeys
EOF
chmod 700 lala/root/.ssh/
chmod 600 lala/root/.ssh/authorized_keys

# erasing ssh host keys from template
rm -f lala/etc/ssh/ssh_host_*

# ssh host keys get created by netbsd's sshd init script
# no need to deal with that here (although we would have better entropy)

echo -n un-mounting lala/ ...
umount lala/ && echo done
rmdir lala/

# we're using it right away
#drbdadm secondary $guest

# xenbr0 -- perimeter snat
#    br0 -- guests' vlans
echo -n guest config...
mkdir -p /data/guests/$guest/lala/
cat > /data/guests/$guest/$guest <<EOF && echo done
kernel = "$kernel"
root = "xbd0a"
#extra = "-v -s"
name = "$guest"
memory = 1024
vcpus = 2
disk = ['phy:/dev/drbd/by-res/$guest/0,xvda,w']
vif = [ 'bridge=guestbr0,vifname=$guest.0',
        'bridge=guestbr0,vifname=$guest.1']
#type = "pvh"
EOF

# resource should be fully up and running before trying to start the guest on it
#Error: Can't open /dev/drbd/by-res/dnc16/0. Read-only file system.
echo starting guest $guest
xl create /data/guests/$guest/$guest && echo -e \\nGUEST $guest HAS BEEN STARTED
echo up > /data/guests/$guest/state
echo

