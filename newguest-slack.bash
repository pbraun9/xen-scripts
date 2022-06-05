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
echo SLACKWARE XEN GUEST CREATION
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
tmpfs /dev/shm tmpfs defaults 0 0
proc /proc proc defaults 0 0
EOF

echo -n hostname $short ...
echo $short > lala/etc/HOSTNAME && echo done

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

# WARNING ESCAPES ARE IN THERE
echo -n rc.inet1 ...
cat > lala/etc/rc.d/rc.inet1 <<EOF && echo done
#!/bin/bash

echo rc.inet1 PATH is \$PATH

if [[ \$1 = stop || \$1 = down ]]; then
	/etc/rc.d/rc.sshd stop
	route delete default
	ifconfig eth0 down
	ifconfig lo down
else
	echo -n lo ...
	ifconfig lo up && echo done

	echo -n eth0 ...
	ifconfig eth0 $ip up && echo done

	echo -n default route ...
	route add default gw $gw && echo done

	# self-verbose
	/etc/rc.d/rc.sshd start
fi
EOF
chmod +x lala/etc/rc.d/rc.inet1

# in case template had host keys within
echo clean-up ssh host keys
rm -f lala/etc/ssh/ssh_host_*

# NO NEED ON SLACKWARE - ALL HOST KEYS GET GENERATED ANYHOW

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
root = "/dev/xvda1 ro console=hvc0 mitigations=off"
#extra = "init=/bin/bash"
name = "$guest"
memory = 1024
vcpus = 2
disk = ['phy:/dev/drbd/by-res/$guest/0,xvda1,w']
vif = [ 'bridge=guestbr0, vifname=$guest' ]
type = "pvh"
EOF

echo starting guest $guest
xl create /data/guests/$guest/$guest && echo -e \\nGUEST $guest HAS BEEN STARTED
echo up > /data/guests/$guest/state
echo

