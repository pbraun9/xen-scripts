
# defines $ip
function dec2ip {
	[[ -z $prefix ]] && echo function dec2ip requires \$prefix from /etc/dnc.conf && exit 1
	[[ -z $guestid ]] && echo function dec2ip requires \$guestid && exit 1

	# hex from dec
        tmp=`printf "%x" $guestid`

	if (( `echo -n $tmp | wc -c` < 2 )); then
		tmp=000$tmp
	elif (( `echo -n $tmp | wc -c` < 3 )); then
                tmp=00$tmp
        elif (( `echo -n $tmp | wc -c` < 4 )); then
                tmp=0$tmp
	fi

        c=`echo $tmp | sed -r 's/(..)../\1/'`
        d=`echo $tmp | sed -r 's/..(..)/\1/'`
	unset tmp # will this break set -e in case $tmp wasn't necessary?

	(( debug > 0 )) && echo c is $c
	(( debug > 0 )) && echo d is $d

	# prefix from config and /16 suffix from hex
        ip=$prefix.$(( 0x$c )).$(( 0x$d ))

	unset tmp c d
}

