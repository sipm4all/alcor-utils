#!/bin/sh

BCR_DIR=/au/conf/bcr
PCR_DIR=/au/conf/pcr
RDOUT_CONF=/au/conf/readout.conf
CONN=/au/etc/connection2.xml

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [chip] [channel]"
    exit 1
fi
theChip=$1
theChannel=$2

SWITCH="-s -i -m 0x0 -p 1 --oneChannel $theChannel"

ECCR=0xb81b ### Iratio = 0
ECCR=0xb83f ### Iratio = 1

while read -r chip lane eccr bcr pcr; do
 if [ "$chip" = "$theChip" ]; then
     echo Programming $chip
     /au/control/alcorInit.py $CONN kc705 -c $chip $SWITCH --eccr $ECCR --bcrfile ${BCR_DIR}/$bcr.bcr --pcrfile ${PCR_DIR}/$pcr.pcr
 fi
done < $RDOUT_CONF
