#! /usr/bin/env bash

DEV=/dev/ML$1
sudo /au/usb/usbreset $(/au/usb/find_usb_device.sh $DEV | grep path | awk {'print $2'})
sleep 3

/au/masterlogic/start_masterlogic_server.sh $1
