#! /usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "usage: [device] [chip] [sleep]"
    exit 1
fi
device=$1
chip=$2
sleep=$3

### collect data
/au/readout/bin/ureadout --connection ${AU_IPBUS_CONNECTIONS} --usleep 10000000 --occupancy 1024 --device $device --chip $chip --channel 0 --integrated $sleep --output /tmp/test > /tmp/test.log

### read integrated time from log
seconds=$(grep seconds /tmp/test.log | awk {'print $1'})

### count rollovers from data
rollovers=$(od -An -tx4 -w4 -v /tmp/test.chip_0.channel_0.alcor.dat  | grep 5c5c5c5c | wc -l)

frequency=$(echo "32768 * $rollovers / $seconds * 0.0000001" | bc)

echo $frequency MHz

