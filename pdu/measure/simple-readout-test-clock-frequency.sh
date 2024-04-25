#! /usr/bin/env bash

if [ "$#" -ne 4 ]; then
    echo "usage: [device] [chip] [lane] [sleep]"
    exit 1
fi
device=$1
chip=$2
lane=$3
sleep=$4

filter=15

### reset
#/au/readout/bin/deep-reset --connection /etc/drich/drich_ipbus_connections.xml --device $device --chip $chip

### collect data
/au/readout/bin/simple-readout --connection /etc/drich/drich_ipbus_connections.xml --filter $filter --device $device --chip $chip --lane $lane --integrated $sleep --usleep 100 --output /tmp/simple-readout.$device > /tmp/simple-readout.$device.$chip.$lane.log

### read integrated time from log
seconds=$(grep seconds /tmp/simple-readout.$device.$chip.$lane.log | awk {'print $1'})

### count rollovers from data
rollovers=$(od -An -tx4 -w4 -v /tmp/simple-readout.$device.chip_$chip.lane_$lane.alcor.dat  | grep 5c5c5c5c | wc -l)

frequency=$(echo "32768 * $rollovers / $seconds" | bc)

echo $frequency MHz

