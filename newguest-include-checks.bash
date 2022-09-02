
[[ ! -d /etc/drbd.d/ ]] && echo /etc/drbd.d/ not found && exit 1

if [[ `drbdadm status $guest` ]]; then
        echo DRBD RESOURCE $guest IS FINE
else
        echo DRBD RESOURCE $guest HAS AN ISSUE
        exit 1
fi
echo

# /data/ is a shared among the nodes
[[ -z `mount | grep ' on /data '` ]] && echo /data/ is not mounted && exit 1

# assuming this folder structure on /data/
for d in /data/guests /data/kernels /data/templates; do
        [[ ! -d $d/ ]] && echo create a shared-disk $d/ folder first && exit 1
done; unset d

