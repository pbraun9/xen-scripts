#!/bin/bash
set -e

pingg() {
	echo -n $1...
	ping -W1 -c1 $1 >/dev/null && echo UP || echo DOWN
}

for host in `grep ^10.8.8 /etc/hosts | awk '{print $3}'`; do
	pingg $host
done; unset host

