#! /usr/bin/env bash

#/au/pdu/conf/init.sh all &> /dev/null
#/au/pdu/control/init.sh all &> /dev/null

if [ "$#" -ne 2 ]; then
    echo "usage: $0 [name] [sleep]"
    exit 1
fi
name=$1
sleep=$2

devices=$(awk '$1 !~ /^#/' ${AU_READOUT_CONFIG} | awk {'print $4'} | sort | uniq | tr '\n' ' ')
for device in $devices; do
    [[ $name != "all" ]] && [[ $name != $device ]] && continue
    echo " --- $device "
    /au/pdu/control/init.sh $device
    chips=$(awk -v device="$device" '$1 !~ /^#/ && $4 == device' ${AU_READOUT_CONFIG} | awk {'print $5, $6'} | tr '\n' ' ')
    for chip in $chips; do
#	/au/pdu/measure/the_sequence.sh $device $chip 0xb01b	
	for lane in {0..3}; do
	    frequency=$(/au/pdu/measure/simple-readout-test-clock-frequency.sh $device $chip $lane $sleep | awk {'print $1'})
	    echo "$device chip-$chip lane-$lane: $frequency Hz"
	    influx_write.sh "kc705,device=$device,name=clock-test,chip=$chip,lane=$lane value=$frequency"
	done
    done
done
