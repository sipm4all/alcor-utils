#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 [name]"
    exit 1
fi
name=$1

devices=$(awk '$1 !~ /^#/' ${AU_READOUT_CONFIG} | awk {'print $4'} | sort | uniq | tr '\n' ' ')
for device in $devices; do
    [[ $name != "all" ]] && [[ $name != $device ]] && continue
    echo " --- alcorInit on $device "
    /home/eic/bin/alcor-device-init.sh ${device} all
done
