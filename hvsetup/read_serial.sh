#! /usr/bin/env bash

dev=`readlink -f $1`
udevadm info -a -p $(udevadm info -q path -n $dev) | grep serial 
