#! /usr/bin/env bash

if [ "$#" -ne 6 ]; then
    echo " usage: $0 [device] [chip] [channel] [vth] [offset] [timer] "
    exit 1
fi
device=$1
chip=$2
channel=$3
vth=$4
offset=$5
timer=$6

for threshold in {0..63}; do
    /au/pdu/measure/rate.sh $device $chip $channel --min_timer 31250 --min_counts 1000 --max_timer $timer --range 2 --vth $vth --offset $offset --threshold $threshold | awk {'print $3, $15'} 
done | tee /tmp/thrscan.dat

/au/pdu/measure/thrscan.py "${device} chip-${chip} chan-${channel} (vth=${vth}, off=${offset})"
cp /tmp/thrscan.png ~/DATA/.

/home/eic/bin/telegram_picture.sh /tmp/thrscan.png "thrscan"
