#!/bin/bash

debug=0

source /root/xen/newguest-functions.bash
source /etc/dnc.conf

# network is 10.1.0.0/16
# 10.1.0.1 --> 10.1.4.255
# starts at tcp port 1024
for minor in `seq 1 1279`; do
	(( port = 1023 + minor ))
	dec2ip
	ip=10.1.$suffix
	cat <<EOF
                iif \$nic tcp dport $port dnat $ip:22;
EOF
	unset port suffix ip
done
unset minor

