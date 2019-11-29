#!/bin/bash

echo HARDWARE
dsh -e -g cluster "dmidecode -t system | grep 'Product Name'"
echo ''

echo XEN VERSIONS
dsh -e -g xen "xl dmesg | head | grep 'Xen version' | sed 's/(gcc .*$//'"
echo ''

echo LINUX VERSIONS
dsh -e -g cluster "uname -r"
dsh -e -g cluster "file /vmlinuz"
dsh -e -g cluster "ls -lhF /lib/modules/"
echo ''

echo DOM0 KERNEL ARG
dsh -e -g xen "grep xen.gz /extlinux.conf"
echo ''

echo FILE-SYSTEMS
#dsh -e -g cluster "file -sL /dev/sda1"
dsh -e -g cluster "mount | egrep '(^/dev|type nfs[^d])'"
echo ''

echo MEMORY \(MB\)
dsh -e -g cluster "free -m | grep ^Mem"
echo ''

#echo DOM0 WEIGHT BOOT ARG
#dsh -e -g xen "grep sched-credit /etc/rc.d/rc.local"
#echo ''

echo DOM0 WEIGHT
dsh -e -g xen "xl sched-credit | grep Domain-0"
echo ''

echo DOM0 BALLOON
dsh -e -g xen "grep balloon /etc/xen/xl.conf"
echo ''

#echo NETWORK LAYER 1
#dsh -e -g cluster -s running.hosts.bash.netif
#echo ''

echo NETWORK AGGREGATE
dsh -e -g cluster "cat /sys/class/net/bonding_masters /sys/class/net/bond0/speed"
dsh -e -g cluster "cat /proc/net/bonding/bond0 | egrep '^Speed|^Bonding Mode'"
echo ''

echo JUMBO FRAMES
dsh -e -g cluster "for netif in eth1 pubbr0 eth2 eth3 bond0 xenbr0; do echo -n \$netif: ; ifconfig \$netif | head -1 | awk '{print \$NF}'; done; unset netif"
echo ''

echo QUEUE LENGTH
dsh -e -g cluster "for netif in eth1 pubbr0 eth0 eth2 eth3 bond0 xenbr0; do echo -n \$netif: ; ifconfig \$netif | grep txqueuelen | awk '{print \$4}'; done; unset netif"
echo ''

echo LINK STATUS
dsh -e -g xen mii-tool eth{0,1,2,3}
echo

echo GRO
dsh -e -g cluster "for nic in eth1 eth0 eth2 eth3; do echo -n \$netif: ; ethtool -k \$nic 2>/dev/null | grep gro; done; unset nic"
echo ''

echo BNX2FIX
dsh -e -g cluster "cat /etc/modprobe.d/bnx2.conf"
dsh -e -g cluster "cat /sys/module/bnx2/parameters/disable_msi"
echo ''

echo PUBLIC NETWORK
dsh -e -g cluster "ping -c1 -W1 208.67.220.220 >/dev/null && echo OK || echo NOK"
echo''

echo PUBLIC NAME RESOLUTION
dsh -e -g cluster "ping -c1 -W1 opendns.com >/dev/null && echo OK || echo NOK"
echo ''

echo PACKAGES
dsh -e -g cluster "ls -1 /var/log/packages/ | grep tigervnc"

