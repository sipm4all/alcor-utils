#!/bin/sh

if [ "$#" -ne 3 ]]; then
    echo "usage: $0 [device] [chip] [channel]"
    exit 1
fi
device=$1
theChip=$2
theChannel=$3

RDOUT_CONF=/au/pdu/conf/readout.${device}.conf
CONN=${AU_IPBUS_CONNECTIONS}
#SWITCH="-s -i -m 0x0 -p 1 --oneChannel $theChannel"
SWITCH="-s -m 0x0 -p 1 --oneChannel $theChannel"

ECCR=0x381b ### Iratio = 0
ECCR=0x383f ### Iratio = 1

while read -r chip lane eccr bcr pcr; do
 if [ "$chip" = "$theChip" ]; then
     echo Programming $chip
     /au/control/alcorInit.py $CONN $device -c $chip $SWITCH --eccr $ECCR --bcrfile /au/pdu/conf/bcr/$bcr.bcr --pcrfile /au/pdu/conf/pcr/$pcr.pcr
 fi
done < $RDOUT_CONF
