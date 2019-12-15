#!/bin/bash

echo HARDWARE
dsh -e -g xen "dmidecode -t system | grep 'Product Name'"
echo ''

echo XEN VERSIONS
dsh -e -g xen "xl dmesg | head | grep 'Xen version' | sed 's/(gcc .*$//'"
echo ''

echo LINUX VERSIONS
dsh -e -g xen "uname -r"
dsh -e -g xen "file /vmlinuz"
dsh -e -g xen "ls -lhF /lib/modules/"
echo ''

echo DOM0 KERNEL ARG
dsh -e -g xen "grep xen.gz /extlinux.conf"
echo ''

echo FILE-SYSTEMS
#dsh -e -g xen "file -sL /dev/sda1"
dsh -e -g xen "mount | grep -E '(^/dev|type nfs[^d])'"
echo ''

echo MEMORY \(MB\)
dsh -e -g xen "free -m | grep ^Mem"
echo ''

#echo DOM0 WEIGHT BOOT ARG
#dsh -e -g xen "grep sched-credit /etc/rc.d/rc.local"
#echo ''

echo DOM0 WEIGHT
dsh -e -g xen "xl sched-credit | grep Domain-0"
echo ''

echo DOM0 BALLOON \(may be empty\)
dsh -e -g xen "grep -vE '^[[:space:]]*(#|$)' /etc/xen/xl.conf"
echo ''

#echo NETWORK LAYER 1
#dsh -e -g xen -s running.hosts.bash.netif
#echo ''

echo NETWORK AGGREGATE
dsh -e -g xen "cat /sys/class/net/bonding_masters /sys/class/net/bond0/speed"
dsh -e -g xen "cat /proc/net/bonding/bond0 | grep -E '^Speed|^Bonding Mode'"
echo ''

echo JUMBO FRAMES
dsh -e -g xen "for netif in eth1 xenbr0 eth2 eth3 bond0 clusterbr0; do echo -n \$netif: ; ifconfig \$netif | head -1 | awk '{print \$NF}'; done; unset netif"
echo ''

echo QUEUE LENGTH
dsh -e -g xen "for netif in eth1 xenbr0 eth0 eth2 eth3 bond0 clusterbr0; do echo -n \$netif: ; ifconfig \$netif | grep txqueuelen | awk '{print \$4}'; done; unset netif"
echo ''

echo LINK STATUS
dsh -e -g xen mii-tool eth{0,1,2,3}
echo

echo GRO
dsh -e -g xen "for nic in eth1 eth0 eth2 eth3; do echo -n \$netif: ; ethtool -k \$nic 2>/dev/null | grep gro; done; unset nic"
echo ''

echo BNX2 FIX
dsh -e -g xen "cat /etc/modprobe.d/bnx2.conf"
echo ''

echo BNX2 STATUS
dsh -e -g xen "cat /sys/module/bnx2/parameters/disable_msi"
echo ''

echo PUBLIC NETWORK
dsh -e -g xen "ping -c1 -W2 208.67.220.220 >/dev/null && echo OK || echo NOK"
echo''

echo PUBLIC NAME RESOLUTION
dsh -e -g xen "ping -c1 -W1 opendns.com >/dev/null && echo OK || echo NOK"
echo ''

echo CLUSTER HEARTBEAT
dsh -e -g xen "ssh slack1hb hostname"
dsh -e -g xen "ssh slack2hb hostname"
dsh -e -g xen "ssh slack3hb hostname"
dsh -e -g xen "ssh slack4hb hostname"
echo ''

