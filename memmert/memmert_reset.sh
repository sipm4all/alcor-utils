#! /usr/bin/env bash

DEV=/dev/MEMMERT
sudo /au/usb/usbreset $(/au/usb/find_usb_device.sh $DEV | grep path | awk {'print $2'})

/au/memmert/start_memmert_server.sh
