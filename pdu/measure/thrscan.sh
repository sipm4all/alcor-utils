#! /usr/bin/env bash

if [ "$#" -ne 5 ]; then
    echo " usage: $0 [device] [chip] [channel] [vth] [offset] "
    exit 1
fi
device=$1
chip=$2
channel=$3
vth=$4
offset=$5

for threshold in {0..63}; do
    /au/pdu/measure/rate.sh $device $chip $channel --range 2 --vth $vth --offset $offset --threshold $threshold | awk {'print $3, $15'} 
done | tee /tmp/thrscan.dat

/au/pdu/measure/thrscan.py
cp /tmp/thrscan.png ~/DATA/.
