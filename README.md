# XEN wrapper scripts for nobudget

### requirements

- KSH93
- DSH (ClusterIt)

_assuming a [shared](https://pub.nethence.com/storage/) /data/ volume across the nodes, be it NFS, GFS2 or OCFS2_

	mkdir -p /data/guests/ /data/kernels/ /data/templates/
	chmod 700 /data/guests/ /data/kernels/ /data/templates/

### newguest-* scripts

_assuming [XEN templates](https://pub.nethence.com/xen/) with sysprep built-in_

- bashrc & completion
- timezone
- package repositories
- kernel modules (namely tmem)
- file index

_note only those are the steps taken care of by the script_

- fstab
- network setup
- ssh host keys clean-up
- ssh authorized keys

