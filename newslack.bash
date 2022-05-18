#!/bin/bash
set -e

[[ ! -d /etc/drbd.d/ ]] && echo /etc/drbd.d/ not found && exit 1

# /data/ is a shared among the nodes
for d in /data/guests /data/kernels /data/templates; do
	[[ ! -d $d/ ]] && echo create a shared-disk $d/ folder first && exit 1
done; unset d

#[[ -z $2 ]] && echo usage: ${0##*/} GUEST-RESOURCE GUEST-HOSTNAME && exit 1
#guest=$1
#name=$2
#short=${name%%\.*}

[[ -z $1 ]] && echo usage: ${0##*/} MINOR && exit 1
minor=$1
guest=dnc$minor
name=dnc$minor
short=dnc$minor

[[ ! -f /etc/dnc.conf ]] && could not find /etc/dnc.conf && exit 1
source /etc/dnc.conf
[[ ! -n $pubkeys ]] && echo \$pubkeys not defined && exit 1

echo SLACKWARE XEN/PV GUEST CREATION
# XEN/PVH
echo

# possibly diskless
echo -n making BTRFS file-system...
mkfs.btrfs /dev/drbd/by-res/$guest/0 >/dev/null && echo done
#echo -n making REISER4 file-system...
#mkfs.reiser4 -y /dev/drbd/by-res/$guest/0 && echo done

mkdir -p /data/guests/$guest/lala/
cd /data/guests/$guest/
echo -n mounting into lala/ ...
mount /dev/drbd/by-res/$guest/0 lala/ && echo done

# TODO show progress while extracting
echo extracting slackware template
[[ -z `mount -t btrfs | grep /data/guests/$guest/lala` ]] && echo $guest file-system is not mounted && exit 1
#[[ -z `mount -t reiser4 | grep /data/guests/$guest/lala` ]] && echo $guest file-system is not mounted && exit 1
time nice tar xpf /data/templates/slack.tar --numeric-owner -C lala/ && echo done
echo

echo SYSPREP FOR HOSTNAME $name
echo

echo -n hostname $name ...
echo $short > lala/etc/HOSTNAME && echo done

# we're lucky the dnc.conf evaluation works on $ip even though it was loaded before $minor got defined
echo tuning /etc/hosts
mv lala/etc/hosts lala/etc/hosts.dist
echo -e "127.0.0.1\t\tlocalhost.localdomain localhost" > lala/etc/hosts
echo -e "::1\t\t\tlocalhost.localdomain localhost" >> lala/etc/hosts
echo -e "${ip%/*}\t$short.localdomain $short" >> lala/etc/hosts
[[ -n $gw ]] && echo -e "$gw\t\tgw" >> lala/etc/hosts
for dns in dns1 dns2 dns3; do
	[[ -n ${!dns} ]] && echo -e "${!dns}\t\t$dns" >> lala/etc/hosts
done; unset dns

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

# erasing previous settings from tpl
rm -f lala/etc/resolv.conf
for dns in dns1 dns2 dns3; do
	[[ -n ${!dns} ]] && echo -e "nameserver ${!dns}" >> lala/etc/resolv.conf
done; unset dns

# template should NOT have host keys within, erasing anyways
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

echo -n un-mounting lala/ ...
umount lala/ && echo done
rmdir lala/

# xenbr0 -- perimeter nat
# guestbr0 -- guest vlan nat
echo -n writing guest config...
cat > /data/guests/$guest/$guest <<EOF && echo done
kernel = "/data/kernels/vmlinuz"
root = "/dev/xvda1 ro console=hvc0 mitigations=off"
#extra = "init=/bin/bash"
name = "$guest"
#memory = 7168
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

