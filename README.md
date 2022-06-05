# XEN wrapper scripts for nobudget

### requirements

_assuming a [shared](https://pub.nethence.com/storage/) /data/ volume across the nodes, be it NFS, GFS2 or OCFS2_

	mkdir -p /data/guests/ /data/kernels/ /data/templates/
	chmod 700 /data/guests/ /data/kernels/ /data/templates/

### newguest-* scripts

_assuming [XEN templates](https://pub.nethence.com/xen/) already has sysprep built-in incl._

- bashrc
- timezone
- package repositories
- kernel modules (namely tmem)

_those are the steps taken care of_

- fstab
- network setup
- ssh host keys clean-up
- ssh authorized keys

