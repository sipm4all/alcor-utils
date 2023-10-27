#! /usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo " usage: $0 [name] [mode] "
    exit 1
fi
name=$1
mode=$2    

readout_devices=$(awk '$1 !~ /^#/' /etc/drich/drich_readout.conf | awk {'print $4'} | sort | uniq | tr '\n' ' ')
trigger_devices=$(awk '$1 !~ /^#/' /etc/drich/drich_trigger.conf | awk {'print $2'} | sort | uniq | tr '\n' ' ')
devices=$(echo $readout_devices $trigger_devices | tr ' ' '\n' | sort | uniq | tr '\n' ' ')

for device in $devices; do
    [[ $name != "all" ]] && [[ $name != $device ]] && continue
    /au/pdu/measure/device-interprocess.sh ${device} "${mode}" & 
done
wait
