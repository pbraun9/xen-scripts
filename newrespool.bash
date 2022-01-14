#!/bin/bash

[[ ! -x /root/xen/newguest.bash ]] && echo /root/xen/newguest.bash executable not found && exit 1

function bias {
	(( one = RANDOM % 3 +1 ))
	(( two = RANDOM % 2 +1 ))
	(( two >= one )) && (( two++ ))
	one=slack${one}
	two=slack${two}
}

for minor in `seq -w 1037 1039`; do
	bias
	echo GENERATING DRBD RESOURCE WITH MIRROR NODES $one $two AND MINOR $minor
	/root/xen/newres.bash $one $two $minor
	echo
done; unset minor

