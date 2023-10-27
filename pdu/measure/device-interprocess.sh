#! /usr/bin/env bash

### 0x3f9 -- start of run
### 0x3fd -- start of spill

if [ "$#" -ne 2 ]; then
    echo " usage: $0 [device] [mode] "
    exit 1
fi
device=$1
modes=$2

### detect spill down transition
prevspill=0
while true; do
    spill=$(/au/readout/bin/register --connection /etc/drich/drich_ipbus_connections.xml --device $device --node regfile.status | awk {'print $3'})
    [[ $prevspill -eq 1 ]] && [[ $spill -eq 0 ]] && break
    prevspill=$((spill))
    sleep 0.001
done

for mode in $modes; do
    /au/pdu/measure/interprocess.py $device $mode
    sleep 0.1
done

echo " --- end of spill "
