#!/bin/bash
set -e

# no need for $tpl here since we already defined that while cloning the origin snapshot
[[ -z $1 ]] && echo usage: "${0##*/} <drbd minor> [guest hostname]" && exit 1
minor=$1
[[ -n $2 ]] && guest=$2 || guest=dnc$minor

guestid=$minor
name=$guest
short=${name%%\.*}

source /etc/dnc.conf
source /usr/local/lib/dnclib.bash

# check drbd/lvm resource status
source /usr/local/lib/dnclib-checks.bash

# gw and friends got sourced by dnc.conf
# but guest ip gets eveluated by dec2ip function
dec2ip

[[ -z $ip ]] && bomb missing \$ip
[[ -z $gw ]] && bomb missing \$gw

echo DEBIAN SYSTEM PREPARATION
echo

# note drbd resource is possibly diskless

mkdir -p /data/guests/$guest/lala/

echo -n mounting reiser4 wa...
mount -o async,noatime,nodiratime,txmod=wa,discard /dev/drbd/by-res/$guest/0 /data/guests/$guest/lala/ \
	&& echo done || bomb failed to mount reiser4 for $guest

#echo -n mounting butterfs lzo...
#mount -o compress=lzo /dev/drbd/by-res/$guest/0 /data/guests/$guest/lala/
# (already resized)

echo

# TODO use absolute path instead
cd /data/guests/$guest/

#echo -n erasing previous /etc/fstab from template...
#cat > lala/etc/fstab <<EOF && echo done
#/dev/xvda1 / btrfs rw,noatime,nodiratime,space_cache=v2,compress=lzo,discard 0 0
#devpts /dev/pts devpts gid=5,mode=620 0 0
#tmpfs /tmp tmpfs rw,nodev,nosuid,noatime,relatime 0 0
#proc /proc proc defaults 0 0
#EOF

echo -n hostname $short ...
echo $short > lala/etc/hostname && echo done

# ip got defined by dec2ip
#echo -n tuning /etc/hosts ...
#echo 127.0.0.1 localhost.localdomain localhost > lala/etc/hosts
#echo ::1 localhost.localdomain localhost >> lala/etc/hosts
#echo ${ip%/*} $short.localdomain $short >> lala/etc/hosts
#[[ -n $gw ]] && echo $gw gw.localdomain gw >> lala/etc/hosts && echo done

# here sourcing var names, not vars themselves (requires BASH)
#echo adding dns entries to /etc/hosts
#for dns in dns1 dns2 dns3 dns4; do
#        [[ -n ${!dns} ]] && echo ${!dns} $dns >> lala/etc/hosts
#done; unset dns

echo -n writing hosts ...
cat > lala/etc/hosts <<EOF && echo done
127.0.0.1       localhost.localdomain localhost
::1             localhost.localdomain localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

${ip%/*} $short
$gw gw
$dns1 dns1
$dns2 dns2
$dns3 dns3
EOF
#$dns0 dns0

# here sourceing the vars themselves
#echo -n erasing previous /etc/resolv.conf from tpl...
#rm -f lala/etc/resolv.conf
#for dns in $dns1 $dns2 $dns3 $dns4; do
#        echo nameserver $dns >> lala/etc/resolv.conf
#done && echo done; unset dns
echo -n writing resolv.conf ...
cat > lala/etc/resolv.conf <<EOF && echo done
nameserver 10.1.255.253
nameserver 10.1.255.252
nameserver 10.1.255.251
EOF
#nameserver 10.1.255.254

echo -n network/interfaces ...
cat > lala/etc/network/interfaces <<EOF && echo done
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address $ip/16
	gateway $gw

EOF

# in case template had host keys within
echo clean-up ssh host keys
rm -f lala/etc/ssh/ssh_host_*

# [FAILED] Failed to start OpenBSD Secure Shell server.
# we have better entropy on bare-metal anyway
#ssh-keygen -q -t dsa -f lala/etc/ssh/ssh_host_dsa_key -C root@$name -N ''
#ssh-keygen -q -t rsa -f lala/etc/ssh/ssh_host_rsa_key -C root@$name -N ''
echo generating ECDSA and EDDSA host keys
ssh-keygen -q -t ecdsa -f lala/etc/ssh/ssh_host_ecdsa_key -C root@$short -N ''
ssh-keygen -q -t ed25519 -f lala/etc/ssh/ssh_host_ed25519_key -C root@$short -N ''

echo -n adding pubkeys...
mkdir -p lala/root/.ssh/
cat > lala/root/.ssh/authorized_keys <<EOF && echo done
$pubkeys

EOF
chmod 700 lala/root/.ssh/
chmod 600 lala/root/.ssh/authorized_keys

# ADDITIONAL FIXUP - template out of sync
#echo -n writing sources.list ...
#cat > lala/etc/apt/sources.list <<EOF && echo done
#deb http://ftp.ro.debian.org/debian/ bullseye main contrib non-free
#deb http://ftp.ro.debian.org/debian/ bullseye-updates main contrib non-free
#deb http://ftp.ro.debian.org/debian/ bullseye-backports main contrib non-free
#deb http://security.debian.org/debian-security bullseye-security main contrib non-free
#EOF

echo -n un-mounting...
umount /data/guests/$guest/lala/ && echo done
rmdir /data/guests/$guest/lala/

echo -n writing guest config...
cat > /data/guests/$guest/$guest <<EOF && echo done
kernel = "/data/kernels/5.2.21.domureiser4.vmlinuz"
root = "/dev/xvda1 ro console=hvc0 net.ifnames=0 biosdevname=0 mitigations=off"
#extra = "init=/bin/bash"
name = "$guest"
memory = 1024
vcpus = 2
disk = ['phy:/dev/drbd/by-res/$guest/0,xvda1,w']
vif = [ 'bridge=guestbr0, vifname=$guest' ]
type = "pvh"
EOF
# netcfg/do_not_use_netplan=true
echo

#echo starting guest $guest
#xl create /data/guests/$guest/$guest && echo -e \\nGUEST $guest HAS BEEN STARTED
#echo up > /data/guests/$guest/state
dnc-startguest-lowram.bash $guest

