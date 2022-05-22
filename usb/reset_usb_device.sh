#! /usr/bin/env bash

dev=$1
usb=$(/au/usb/find_usb_device.sh $dev | grep path | awk {'print $2'})
sudo /au/usb/usbreset $usb
