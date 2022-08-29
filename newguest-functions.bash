
[[ ! -d /etc/drbd.d/ ]] && echo /etc/drbd.d/ not found && exit 1

if [[ `drbdadm status $guest` ]]; then
        echo DRBD RESOURCE $guest IS FINE
else
        echo DRBD RESOURCE $guest HAS AN ISSUE
        exit 1
fi

# /data/ is a shared among the nodes
for d in /data/guests /data/kernels /data/templates; do
        [[ ! -d $d/ ]] && echo create a shared-disk $d/ folder first && exit 1
done; unset d

# requires minor
# sets suffix
function dec2ip {
	# hex from dec
        tmp=`printf "%x" $minor`

	if (( `echo -n $tmp | wc -c` < 2 )); then
		tmp=000$tmp
	elif (( `echo -n $tmp | wc -c` < 3 )); then
                tmp=00$tmp
        elif (( `echo -n $tmp | wc -c` < 4 )); then
                tmp=0$tmp
	fi

	(( debug > 0 )) && echo tmp is $tmp

        c=`echo $tmp | sed -r 's/(..)../\1/'`
        d=`echo $tmp | sed -r 's/..(..)/\1/'`

	(( debug > 0 )) && echo c is $c
	(( debug > 0 )) && echo d is $d

	# ip /16 suffix from hex
        suffix=$(( 0x$c )).$(( 0x$d ))

	(( debug > 0 )) && echo suffix is $suffix

	unset tmp c d
}

