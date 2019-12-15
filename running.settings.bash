#!/bin/bash

echo SHELL
dsh -e -g xen "grep ^root /etc/passwd"
echo ''

echo SSHD
dsh -e -g xen "grep ^HostKey /etc/ssh/sshd_config"
echo ''

#echo PACKAGES
#dsh -e -g xen "ls -1 /var/log/packages/ | grep tigervnc"
#echo ''

