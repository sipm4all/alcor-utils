#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [chip] [channel]"
    exit 1
fi
chip=$1
channel="$2"
eochannel=$(/au/readout/python/mapping.py --xy2eo $channel)

### check if paused
while [ -f .pause ]; do
    echo " $0: paused"
    sleep 1
done

### scans
if [ -z "$AU_SCANS" ]; then
    echo " --- AU_SCANS undefined "
    exit 1
fi
SCANS=${AU_SCANS}

### make sure firmware is fresh
/au/firmware/program.sh new 210203A62F62A true
sleep 3

### reset masterlogic, we want it in good shape
/au/masterlogic/reset ${chip}
sleep 3

for scan in $AU_SCANS; do
    echo " --- starting ${scan} scan on chip${chip}-${channel} "
    time -p /au/measure/universal_scan_hama2.sh $scan $chip $channel
    echo " --- finished ${scan} scan on chip${chip}-${channel} "
done

