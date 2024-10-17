#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ] || [ -x $3 ]; then
    echo "usage: rate.sh [device] [chip] [eo_channel] [options]"
    exit 1
fi
device=$1
chip=$2
eo_channel=$3
options=${@:4}

/au/pdu/control/alcor_fast_init.sh $device $chip $eo_channel &> /dev/null

#for I in {0..3}; do
#    /au/readout/bin/alcor_register --connection ${AU_IPBUS_CONNECTIONS} --device $device --chip $chip --eccr $I
#    /au/readout/bin/alcor_register --connection ${AU_IPBUS_CONNECTIONS} --device $device --chip $chip --eccr $I --write 0xb03f
#    /au/readout/bin/alcor_register --connection ${AU_IPBUS_CONNECTIONS} --device $device --chip $chip --eccr $I --write 0x383f
#done

output=$(/au/readout/bin/rate --connection ${AU_IPBUS_CONNECTIONS} --device $device --chip $chip --channel $eo_channel $options)
[ -z "$output" ] && exit
echo "$output"

