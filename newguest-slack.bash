#!/bin/ksh
set -e

[[ -z $1 ]] && echo usage: "${0##*/} <DRBD-MINOR> [RESOURCE/GUEST]" && exit 1
minor=$1
[[ -n $2 ]] && guest=$2 || guest=dnc$minor
[[ -n $2 ]] && name=$2 || name=dnc$minor
short=${name%%\.*}
echo

if [[ `drbdadm status $guest` ]]; then
	echo DRBD RESOURCE $guest IS FINE
	echo
else
	echo DRBD RESOURCE $guest HAS AN ISSUE
	echo
	exit 1
fi

source /root/xen/newguest-include.bash

[[ ! -f /etc/dnc.conf ]] && could not find /etc/dnc.conf && exit 1
source /etc/dnc.conf
[[ ! -n $pubkeys ]] && echo \$pubkeys not defined && exit 1

echo SLACKWARE XEN GUEST CREATION
echo

# drbd resource is possibly diskless
tpl=slack
partclone.btrfs --restore --source /data/templates/$tpl.pcl --output /dev/drbd/by-res/$guest/0
mkdir -p /data/guests/$guest/lala/
mount -o compress=lzo /dev/drbd/by-res/$guest/0 /data/guests/$guest/lala/
btrfs filesystem resize max /data/guests/$guest/lala/
unset tpl
echo

echo SYSTEM PREPARATION
echo

# TODO use absolute path
cd /data/guests/$guest/

echo -n hostname $short ...
echo $short > lala/etc/HOSTNAME && echo done

# we're lucky the dnc.conf evaluation works on $ip even though it was loaded before $minor got defined
echo -n tuning /etc/hosts ...
echo 127.0.0.1 localhost.localdomain localhost > lala/etc/hosts
echo ::1 localhost.localdomain localhost >> lala/etc/hosts
echo ${ip%/*} $short.localdomain $short >> lala/etc/hosts
[[ -n $gw ]] && echo $gw gw.localdomain gw >> lala/etc/hosts && echo done

echo -n adding dns entries to /etc/hosts ...
# here sourcing var names, not vars themselves
for dns in dns1 dns2 dns3; do
	[[ -n ${!dns} ]] && echo ${!dns} $dns >> lala/etc/hosts
done && echo done; unset dns

echo -n erasing previous /etc/resolv.conf from tpl...
rm -f lala/etc/resolv.conf
for dns in $dns1 $dns2 $dns3; do
	echo nameserver $dns >> lala/etc/resolv.conf
done && echo done; unset dns

# erasing previous settings from tpl
# WARNING ESCAPES ARE IN THERE
echo -n rc.inet1...
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

# template should NOT have host keys within, erasing anyways
echo clean-up ssh host keys
rm -f lala/etc/ssh/ssh_host_*

# we have better entropy on bare-metal
#ssh-keygen -q -t dsa -f lala/etc/ssh/ssh_host_dsa_key -C root@$name -N ''
#ssh-keygen -q -t rsa -f lala/etc/ssh/ssh_host_rsa_key -C root@$name -N ''
#ssh-keygen -q -t ecdsa -f lala/etc/ssh/ssh_host_ecdsa_key -C root@$name -N ''
# NO NEED, ALL KEY PAIRS GET GENERATED ANYHOW
#ssh-keygen -q -t ed25519 -f lala/etc/ssh/ssh_host_ed25519_key -C root@$name -N ''

echo -n adding pubkeys...
mkdir -p lala/root/.ssh/
cat > lala/root/.ssh/authorized_keys <<EOF && echo done
$pubkeys
EOF
chmod 700 lala/root/.ssh/
chmod 600 lala/root/.ssh/authorized_keys

# had been fixed within the template
#echo -n FIXING LDCONFIG...
#chroot lala/ ldconfig && echo done
#echo

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

# resource should be fully up and running before trying to start the guest on it
#Error: Can't open /dev/drbd/by-res/dnc16/0. Read-only file system.
echo starting guest $guest
xl create /data/guests/$guest/$guest && echo -e \\nGUEST $guest HAS BEEN STARTED
echo up > /data/guests/$guest/state
echo

