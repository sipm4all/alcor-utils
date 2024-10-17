#! /usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "usage: rate.sh [device] [chip] [eccr] "
    exit 1
fi
device=$1
chip=$2
eccr=$3

echo " --- running THE SEQUENCE on device $device chip $chip with final ECCR $eccr"

for I in {0..3}; do
#    /au/readout/bin/alcor_register --connection ${AU_IPBUS_CONNECTIONS} --device $device --chip $chip --eccr $I --write 0x0000 &> /dev/null
#    /au/readout/bin/alcor_register --connection ${AU_IPBUS_CONNECTIONS} --device $device --chip $chip --eccr $I --write 0xb009 &> /dev/null
    /au/readout/bin/alcor_register --connection ${AU_IPBUS_CONNECTIONS} --device $device --chip $chip --eccr $I --write 0x3809 &> /dev/null
    /au/readout/bin/alcor_register --connection ${AU_IPBUS_CONNECTIONS} --device $device --chip $chip --eccr $I --write $eccr &> /dev/null
done

