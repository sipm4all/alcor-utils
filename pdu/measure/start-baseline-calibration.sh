#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 [name]"
    exit 1
fi
name=$1
runname=$(date +%Y%m%d-%H%M%S)

devices=$(awk '$1 !~ /^#/' ${AU_READOUT_CONFIG} | awk {'print $4'} | sort | uniq | tr '\n' ' ')

telegram_message.sh "requested baseline calibration: ${runname} ${name}"

for device in $devices; do
    [[ $name != "all" ]] && [[ $name != $device ]] && continue
    echo " --- running baseline calibration: /au/pdu/measure/run-baseline-calibration.sh ${runname} ${device}"
    /au/pdu/measure/run-baseline-calibration.sh ${runname} ${device} &> /tmp/run-baseline-calibration.${device}.log # &
done

