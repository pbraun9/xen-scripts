#!/bin/bash
set -e
echo

[[ ! -d /etc/drbd.d/ ]] && echo /etc/drbd.d/ not found && exit 1

# /data/ is a shared among the nodes
for d in /data/guests /data/kernels /data/templates; do
	[[ ! -d $d/ ]] && echo create a shared-disk $d/ folder first && exit 1
done; unset d

[[ -z $2 ]] && echo -e usage: ${0##*/} GUEST-RESOURCE GUEST-HOSTNAME \\n && exit 1
guest=$1
name=$2
short=${name%%\.*}

echo XEN/PV GUEST CREATION
#echo XEN/PVH GUEST CREATION
echo

# xenbr0 -- perimeter snat
echo -n writing guest config...
mkdir -p /data/guests/$guest/lala/
cat > /data/guests/$guest/$guest <<EOF && echo done
kernel = "/data/kernels/vmlinuz"
root = "/dev/xvda1 ro console=hvc0 mitigations=off"
#extra = "init=/bin/bash"
name = "$guest"
#memory = 7168
memory = 1024
vcpus = 16
disk = ['phy:/dev/drbd/by-res/$guest/0,xvda1,w']
vif = [ 'bridge=xenbr0, vifname=$guest' ]
#type = "pvh"
EOF

# even from here (possibly diskless)
echo -n making REISER4 file-system...
mkfs.reiser4 -y /dev/drbd/by-res/$guest/0 && echo done

cd /data/guests/$guest/
echo -n mounting into lala/ ...
mount /dev/drbd/by-res/$guest/0 lala/ && echo done

echo extracting slackware template
[[ -z `mount -t reiser4 | grep /data/guests/$guest/lala` ]] && echo $guest file-system is not mounted && exit 1
time nice tar xpf /data/templates/slack.tar --numeric-owner -C lala/ && echo done
echo

echo SYSPREP FOR HOSTNAME $name
echo

echo -n hostname $name ...
echo $short > lala/etc/HOSTNAME && echo done

ip=10.0.0.99/24
gw=10.0.0.254
dns1=192.168.122.1

echo -e "127.0.0.1\t\tlocalhost.localdomain localhost" > lala/etc/hosts
echo -e "::1\t\t\tlocalhost.localdomain localhost" >> lala/etc/hosts
echo -e "${ip%/*}\t$short.localdomain $short" >> lala/etc/hosts
[[ -n $gw ]] && echo -e "$gw\t\tgw" >> lala/etc/hosts
for dns in dns1 dns2 dns3; do
	[[ -n ${!dns} ]] && echo -e "${!dns}\t\t$dns" >> lala/etc/hosts
done; unset dns

# WARNING ESCAPES ARE IN THERE
echo -n rc.sshd...
cat > lala/etc/rc.d/rc.sshd <<EOF && echo done
#!/bin/bash

echo rc.sshd PATH is \$PATH

if [[ \$1 = stop ]]; then
	pkill sshd
else
	[[ ! -f /etc/ssh/ssh_host_ed25519_key ]] && ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
	/usr/sbin/sshd
fi
EOF
chmod +x lala/etc/rc.d/rc.sshd

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

	/etc/rc.d/rc.sshd start
fi
EOF
chmod +x lala/etc/rc.d/rc.inet1

echo 'search nethence.com' > lala/etc/resolv.conf
for dns in dns1 dns2 dns3; do
	[[ -n ${!dns} ]] && echo -e "nameserver ${!dns}" >> lala/etc/resolv.conf
done; unset dns

echo -n adding pubkeys...
mkdir lala/root/.ssh/
cat $HOME/.ssh/id_*.pub > lala/root/.ssh/authorized_keys && echo done
#cat > lala/root/.ssh/authorized_keys <<EOF && echo done
#PUBKEY-HERE
#EOF
chmod 700 lala/root/.ssh/
chmod 600 lala/root/.ssh/authorized_keys

#echo -n FIXING LDCONFIG...
#chroot lala/ ldconfig && echo done
#echo

# template should NOT have host keys within, erasing anyways
rm -f lala/etc/ssh/ssh_host_*

echo -n un-mounting lala/ ...
umount lala/ && echo done
rmdir lala/

# resource should be fully up and running before trying to start the guest on it
#Error: Can't open /dev/drbd/by-res/dnc16/0. Read-only file system.
echo starting guest $guest
xl create /data/guests/$guest/$guest && echo -e \\nGUEST $guest HAS BEEN STARTED

echo

