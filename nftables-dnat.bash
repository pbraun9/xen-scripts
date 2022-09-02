#!/bin/bash

debug=0

source /etc/dnc.conf
source /root/xen/newguest-functions.bash

# network is 10.1.0.0/16: 10.1.0.1 - 10.1.4.255
# guestid matches tcp port which starts at 1024
for guestid in `seq 1024 3000`; do
	(( port = guestid ))

	dec2ip # defines ip

	cat <<EOF
                iif \$nic tcp dport $port dnat $ip:22;
EOF
	unset port ip
done
unset guestid

