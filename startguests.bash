#!/bin/bash

rand() {
	rand=`echo $[ $RANDOM % 4 ]`
	(( $rand == 0 )) && echo ubuntu1
	(( $rand == 1 )) && echo slack2
	(( $rand == 2 )) && echo slack3
	(( $rand == 3 )) && echo slack4
	unset rand
}

for guest in `sed -n "/GROUP:guest/,/^$/p" $HOME/clusterit.conf | sed '1d'`; do
	cmd="ssh `rand` xl create /data/guests/$guest/$guest"
	echo $cmd
	$cmd
done; unset guest

