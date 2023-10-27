#! /usr/bin/env bash

if [ "$#" -ne 4 ]; then
    echo "usage: $0 [device] [chip] [lane] [sleep]"
    exit 1
fi
device=$1
chip=$2
lane=$3
sleep=$4

frequency=$(/au/pdu/measure/simple-readout-test-clock-frequency.sh $device $chip $lane $sleep | awk {'print $1'})
echo "$device chip-$chip lane-$lane: $frequency Hz"
influx_write.sh "alcor,device=$device,name=frequency,chip=$chip,lane=$lane value=$frequency"

