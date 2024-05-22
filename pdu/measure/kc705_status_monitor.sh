#! /usr/bin/env bash

if [ $# -ne 1 ]; then
    echo " usage: [device] "
    exit 1
fi
device=$1

while true; do
    line=$(/au/readout/bin/register --connection /etc/drich/drich_ipbus_connections.xml --device ${device} --node regfile.status)
    echo -ne "$line"\\r
done
