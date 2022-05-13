#! /usr/bin/env bash

ls $1 > /dev/null || exit 1

BUSNUM=$(udevadm info --name=$1 --attribute-walk | grep busnum | head -n 1 | sed -n 's/\s*ATTRS{\(\(devnum\)\|\(busnum\)\)}==\"\([^\"]\+\)\"/\4/p')
DEVNUM=$(udevadm info --name=$1 --attribute-walk | grep devnum | head -n 1 | sed -n 's/\s*ATTRS{\(\(devnum\)\|\(busnum\)\)}==\"\([^\"]\+\)\"/\4/p')
lsusb -s $BUSNUM:$DEVNUM

PATH=$(printf "/dev/bus/usb/%03d/%03d\n" $BUSNUM $DEVNUM)
echo "path: $PATH"
