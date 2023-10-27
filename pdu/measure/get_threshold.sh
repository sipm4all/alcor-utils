#! /usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "usage: $0 [device] [chip] [eo_channel]"
    exit 1
fi
device=$1
chip=$2
xy_channel=$3
### R+TEMP ### eo_channel=$(/au/readout/python/mapping.py --xy2eo $xy_channel)
eo_channel=$3 ### R+TEMP ###

pcrfile=$(awk -v chip=$chip '$1 == chip' /au/pdu/conf/readout.$device.conf | awk {'print $5'})
threshold=$(awk -v ch=$eo_channel '$1 == ch' /au/pdu/conf/pcr/$pcrfile.pcr | awk {'print $5'})
echo $threshold


