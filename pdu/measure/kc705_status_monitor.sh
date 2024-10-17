#! /usr/bin/env bash

if [ $# -ne 1 ]; then
    echo " usage: [device] "
    exit 1
fi
device=$1

while true; do
    line=$(/au/readout/bin/register --connection ${AU_IPBUS_CONNECTIONS} --device ${device} --node regfile.status)
    echo -ne "$line"\\r
done
