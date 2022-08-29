#!/bin/bash

# check that nothing >=1024 listens

netstat -lntup --inet | sed 1,2d | awk '{print $4}' | cut -f2 -d: | sort -uV

