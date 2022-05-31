
[[ ! -d /etc/drbd.d/ ]] && echo /etc/drbd.d/ not found && exit 1

# /data/ is a shared among the nodes
for d in /data/guests /data/kernels /data/templates; do
        [[ ! -d $d/ ]] && echo create a shared-disk $d/ folder first && exit 1
done; unset d

