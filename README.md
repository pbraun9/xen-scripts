# Definitely Not a Cloud

_XEN wrapper scripts for [No Budget](https://github.com/pbraun9/nobudget)_

## Requirements

_tested on slackware 15.0_

- a convergent [DRBD farm](https://pub.nethence.com/storage/drbd)
- BASH and KSH93
- [ClusterIt](https://www.garbled.net/clusterit)

## Shared storage

guest vdisks are stored on DRBD/LVM on the `thin` pool (see convergent DRBD farm guide linked above).

guest configs and kernels are stored on shared-disk file-system or network file-system (see the [storage guides](https://pub.nethence.com/storage/) accordingly, be it for NFS, GFS2 or OCFS2).
for that purpose, we are expecting those directories.

	mkdir -p /data/guests/ /data/kernels/ /data/templates/
	chmod 700 /data/guests/ /data/kernels/ /data/templates/

## Guest templates summary

the newguest scripts are expecting a few things to be done already, as for [system preparation for the XEN guests](https://pub.nethence.com/xen/).
the guest templates are vanilla but for those changes.

- bashrc & completion
- timezone
- package repositories
- kernel modules (namely tmem)
- file index
- fstab

only those are the steps taken care of by the newguest scripts.

- network setup
- ssh host keys clean-up
- ssh authorized keys

although some steps can eventually be overwritten during guest deployments for convenience for example

- (fstab)
- (package repositories)

## Usage

### create a new drbd/lvm guest template

check for available drbd minor from the drbd/lvm template range (<1024)

	cd /etc/drbd.d/
	grep minor *.res | sort -V -k3

create a new guest template e.g. with drbd minor 7 on mirror nodes 1 and 2

	/root/new-resource-template.bash pmr1 pmr2 7 debian11jan2023

proceed with the [debian bootstrap guide](https://pub.nethence.com/xen/guest-debian) against that new DRBD volume

	ls -lF /dev/mapper/thin-debian11jan2023
	ls -lF /dev/drbd7

### create a new guest (based on template)

check for available drbd minor from the drbd/lvm guest snapshot range (>=1024)

        cd /etc/drbd.d/
        grep minor *.res | sort -V -k3

create a new snapshot-based drbd volume based on lvm template

	/root/xen/new-resource.bash debian11jan2023 1024

and finally post-tune the guest with the appropriate network settings

	/root/xen/newguest-debian.bash 1024

