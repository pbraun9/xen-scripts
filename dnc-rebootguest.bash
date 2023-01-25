#!/bin/bash

source /usr/local/lib/dnclib.bash

[[ -z $1 ]] && echo -e ${0##*/} GUEST-NAME\\n && exit 1
guest=$1

# we are root already
node=`dnc-running-guest.bash $guest | cut -f1 -d:`
[[ -z $node ]] && bomb could not determine on what node guest $guest lives on
(( debug > 0 )) && echo guest $guest lives on $node

# outputs
echo REBOOTING GUEST $guest ON NODE $node
ssh $node -t xl reboot $guest && echo DONE

