#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo " usage: $0 [device] "
    exit 1 
fi
device=$1

/au/readout/bin/register --connection /etc/drich/drich_ipbus_connections.xml --device $device --node regfile.fwrev
