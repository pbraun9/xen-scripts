#!/bin/ksh

# change PASSWORD and MMONIT accordingly

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/pkg/bin:/usr/pkg/sbin:$HOME/bin
export PKG_PATH=http://cdn.NetBSD.org/pub/pkgsrc/packages/NetBSD/amd64/7.1/All/
export PASSIVE_FTP=yes

[[ ! `uname` = NetBSD ]] && this script is supposed to run on NetBSD systems && exit 1

pkg_add monit

ln -s /usr/pkg/etc/monit/monitrc /root/monitrc
ln -s /usr/pkg/etc/monit/monitrc /etc/monitrc

cd /usr/pkg/etc/monit/
mv monitrc monitrc.dist
sed '/^[[:space:]]*$/d; /^[[:space:]]*#/d' monitrc.dist > monitrc
chmod 600 monitrc
#nmap -p 8080 MMONIT
cat >> monitrc <<-EOF9

set mmonit http://monit:PASSWORD@MMONIT:8080/collector
#check network internal with interface xennet0
#check network local with interface lo0
check filesystem _ with path /
EOF9

cp -f /usr/pkg/share/examples/rc.d/monit /etc/rc.d/monit
echo monit=yes >> /etc/rc.conf
/etc/rc.d/monit start

