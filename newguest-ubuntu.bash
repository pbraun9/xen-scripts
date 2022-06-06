#!/bin/bash
set -e

[[ -z $2 ]] && echo usage: "${0##*/} <TEMPLATE> <DRBD-MINOR> [RESOURCE/GUEST]" && exit 1
tpl=$1
minor=$2
[[ -n $3 ]] && guest=$3 || guest=dnc$minor
[[ -n $3 ]] && name=$3 || name=dnc$minor
short=${name%%\.*}

source /root/xen/newguest-include.bash
source /etc/dnc.conf
[[ ! -n $pubkeys ]] && echo \$pubkeys not defined && exit 1
[[ ! -f /data/templates/$tpl.pcl ]] && echo could not find /data/templates/$tpl.pcl && exit 1

echo
echo DEBIAN/UBUNTU XEN GUEST CREATION
echo

# drbd resource is possibly diskless
partclone.btrfs --restore --source /data/templates/$tpl.pcl --output /dev/drbd/by-res/$guest/0
mkdir -p /data/guests/$guest/lala/
mount -o compress=lzo /dev/drbd/by-res/$guest/0 /data/guests/$guest/lala/
btrfs filesystem resize max /data/guests/$guest/lala/
echo

echo SYSTEM PREPARATION
echo

# TODO use absolute path instead
cd /data/guests/$guest/

echo -n erasing previous /etc/fstab from tpl...
cat > lala/etc/fstab <<EOF && echo done
/dev/xvda1 / btrfs rw,noatime,nodiratime,space_cache=v2,compress=lzo,discard 0 0
devpts /dev/pts devpts gid=5,mode=620 0 0
tmpfs /tmp tmpfs rw,nodev,nosuid,noatime,relatime 0 0
proc /proc proc defaults 0 0
EOF

echo -n hostname $short ...
echo $short > lala/etc/hostname && echo done

# ip with minor as suffix got defined while sourcing dnc.conf
echo -n tuning /etc/hosts ...
echo 127.0.0.1 localhost.localdomain localhost > lala/etc/hosts
echo ::1 localhost.localdomain localhost >> lala/etc/hosts
echo ${ip%/*} $short.localdomain $short >> lala/etc/hosts
[[ -n $gw ]] && echo $gw gw.localdomain gw >> lala/etc/hosts && echo done

# here sourcing var names, not vars themselves (requires BASH)
echo adding dns entries to /etc/hosts
for dns in dns1 dns2 dns3; do
        [[ -n ${!dns} ]] && echo ${!dns} $dns >> lala/etc/hosts
done; unset dns

# here sourceing the vars themselves
echo -n erasing previous /etc/resolv.conf from tpl...
rm -f lala/etc/resolv.conf
for dns in $dns1 $dns2 $dns3; do
        echo nameserver $dns >> lala/etc/resolv.conf
done && echo done; unset dns

echo -n network/interfaces ...
cat > lala/etc/network/interfaces <<EOF && echo done
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address $ip
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

echo -n un-mounting...
umount /data/guests/$guest/lala/ && echo done
rmdir /data/guests/$guest/lala/

echo -n writing guest config...
cat > /data/guests/$guest/$guest <<EOF && echo done
kernel = "/data/kernels/5.2.21.domureiser4.vmlinuz"
root = "/dev/xvda1 ro console=hvc0 net.ifnames=0 biosdevname=0 netcfg/do_not_use_netplan=true mitigations=off"
#extra = "init=/bin/bash"
name = "$guest"
memory = 1024
vcpus = 2
disk = ['phy:/dev/drbd/by-res/$guest/0,xvda1,w']
vif = [ 'bridge=guestbr0, vifname=$guest' ]
type = "pvh"
EOF

#echo starting guest $guest
#xl create /data/guests/$guest/$guest && echo -e \\nGUEST $guest HAS BEEN STARTED
#echo up > /data/guests/$guest/state

/root/xen/startguest-lowram.bash $guest

