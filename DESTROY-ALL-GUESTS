#!/bin/bash

for guest in `xl li | sed 1,2d | awk '{print $1}'`; do xl des $guest; done
unset guest

