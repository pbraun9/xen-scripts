
[[ ! -d /etc/drbd.d/ ]] && bomb /etc/drbd.d/ not found

[[ -z $guest ]] && bomb missing \$guest
drbdadm status $guest >/dev/null || bomb DRBD RESOURCE $guest HAS AN ISSUE

# /data/ is a shared among the nodes
[[ -z `mount | grep ' on /data '` ]] && bomb /data/ is not mounted

# assuming this folder structure on /data/
for d in /data/guests /data/kernels /data/templates; do
        [[ ! -d $d/ ]] && bomb create a shared-disk $d/ folder first
done; unset d

# -z exists 1 and terminates the parent script set -e
# this is why there's -n here instead
[[ -n $pubkeys ]] || bomb missing \$pubkeys

