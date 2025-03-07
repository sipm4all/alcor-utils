#!/bin/sh

if [ "$#" -ne 3 ]]; then
    echo "usage: $0 [device] [chip] [channel]"
    exit 1
fi
device=$1
theChip=$2
theChannel=$3

RDOUT_CONF=/au/pdu/conf/readout.${device}.conf
CONN=/etc/drich/drich_ipbus_connections.xml

SWITCH="-s -i -m 0x0 -p 1 --oneChannel $theChannel"

while read -r chip lane eccr bcr pcr; do
 if [ "$chip" = "$theChip" ]; then
     echo Programming $chip
     /au/control/alcorInit.py $CONN $device -c $chip $SWITCH --eccr 0xb01b --bcrfile /au/pdu/conf/bcr/$bcr.bcr --pcrfile /au/pdu/conf/pcr/$pcr.pcr
 fi
done < $RDOUT_CONF
