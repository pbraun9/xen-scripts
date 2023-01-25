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

echo
echo SLACKWARE SYSTEM PREPARATION
echo

# mounting a thin snapshot (already resized)
# drbd resource is possibly diskless

mkdir -p /data/guests/$guest/lala/

echo -n mounting btrfs-lzo ...
mount -o compress=lzo /dev/drbd/by-res/$guest/0 /data/guests/$guest/lala/ && echo done || exit 1

#echo -n mounting f2fs-lz4 ...
#mount -o rw,noatime,nodiratime,compress_algorithm=lz4,compress_chksum,atgc,gc_merge \
#	/dev/drbd/by-res/$guest/0 /data/guests/$guest/lala/ && echo done || exit 1

# TODO use absolute path instead
cd /data/guests/$guest/

echo -n hostname $short ...
echo $short > lala/etc/HOSTNAME && echo done

# ip got defined by dec2ip
echo -n tuning /etc/hosts ...
echo 127.0.0.1 localhost.localdomain localhost > lala/etc/hosts
echo ::1 localhost.localdomain localhost >> lala/etc/hosts
echo ${ip%/*} $short.localdomain $short >> lala/etc/hosts
[[ -n $gw ]] && echo $gw gw.localdomain gw >> lala/etc/hosts && echo done

# here sourcing var names, not vars themselves (requires BASH)
echo adding dns entries to /etc/hosts
for dns in dns1 dns2 dns3 dns4; do
	[[ -n ${!dns} ]] && echo ${!dns} $dns >> lala/etc/hosts
done; unset dns

# here sourcing the vars themselves
echo -n erasing previous /etc/resolv.conf from template...
rm -f lala/etc/resolv.conf
for dns in $dns1 $dns2 $dns3 $dns4; do
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
	ifconfig eth0 $ip/16 up && echo done

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

#
# override defaults from template
#

echo -n override template fstab ...
cat > lala/etc/fstab <<EOF && echo done
/dev/xvda1 / btrfs defaults,noatime,nodiratime,space_cache=v2,compress=lzo,discard 0 0
devpts /dev/pts devpts gid=5,mode=620 0 0
tmpfs /dev/shm tmpfs defaults 0 0
proc /proc proc defaults 0 0
EOF
# for f2fs
# boot system with additiona kernel argument rootflags=atgc
#/dev/xvda1 / f2fs defaults,noatime,nodiratime,compress_algorithm=lz4,compress_extension=*,compress_chksum,atgc,gc_merge 1 1

# possible w/o tmem
#echo disable boot-time kernel modules
#chmod -x lala/etc/rc.d/rc.modules
#chmod -x lala/etc/rc.d/rc.modules.local

echo reduce buffer/cache usage
echo vm.vfs_cache_pressure = 200 > lala/etc/sysctl.d/reduce-buffer-cache.conf

echo -n un-mounting...
umount /data/guests/$guest/lala/ && echo done
rmdir /data/guests/$guest/lala/

echo -n writing guest config...
cat > /data/guests/$guest/$guest <<EOF && echo done
kernel = "/data/kernels/5.2.21.domureiser4.vmlinuz"
root = "/dev/xvda1 ro console=hvc0 mitigations=off"
#extra = "init=/bin/bash"
name = "$guest"
vcpus = 2
memory = 1024
disk = ['phy:/dev/drbd/by-res/$guest/0,xvda1,w']
vif = [ 'bridge=guestbr0, vifname=$guest' ]
type = "pvh"
EOF
#root = "/dev/xvda1 ro console=hvc0 mitigations=off rootflags=atgc"
#memory = 512
#maxmem = 7168

#echo starting guest $guest
#xl create /data/guests/$guest/$guest && echo -e \\nGUEST $guest HAS BEEN STARTED
#echo up > /data/guests/$guest/state
#echo

dnc-startguest-lowram.bash $guest

