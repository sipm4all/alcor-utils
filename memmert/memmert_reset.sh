#! /usr/bin/env bash

DEV=/dev/MEMMERT
sudo /au/usb/usbreset $(/au/usb/find_usb_device.sh $DEV | grep path | awk {'print $2'})
sleep 3
kill -9 $(cat /tmp/memmert_server.pid)
sleep 3

/au/memmert/start_memmert_server.sh
