#!/bin/bash

source /usr/local/lib/dnclib.bash

[[ -z $1 ]] && echo -e ${0##*/} GUEST-NAME\\n && exit 1
guest=$1

#echo reaching out to guest $guest console

# we are root already
node=`dnc-running-guest.bash $guest | cut -f1 -d:`
[[ -z $node ]] && bomb could not determine on what node guest $guest lives on
(( debug > 0 )) && echo guest $guest lives on $node

echo
echo CONNECTING TO GUEST CONSOLE $guest ON NODE $node - CLOSE WITH Ctrl-]
echo

ssh $node -t xl console $guest && echo DONE || bomb did not manage to reach $guest console on node $node

# TODO CLOSE PREVIOUS CONSOLE SESSIONS

