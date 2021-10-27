#! /usr/bin/env bash

SERIAL=$1
for dev in `ls /dev/ttyUSB*`; do
    udevadm info -a -p $(udevadm info -q path -n $dev) | grep serial | grep $SERIAL && echo "$SERIAL is on $dev"
done
