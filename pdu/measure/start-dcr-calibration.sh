#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 [name]"
    exit 1
fi
name=$1
runname=$(date +%Y%m%d-%H%M%S)

devices=$(awk '$1 !~ /^#/' ${AU_READOUT_CONFIG} | awk {'print $4'} | sort | uniq | tr '\n' ' ')

telegram_message.sh "requested DCR scan: ${runname} ${name} (${devices})"

for device in $devices; do
    [[ $name != "all" ]] && [[ $name != $device ]] && continue
    echo " --- running DCR calibration: /au/pdu/measure/run-dcr-calibration.sh ${runname} ${device}"
    /au/pdu/measure/run-dcr-calibration.sh ${runname} ${device} &> /tmp/run-dcr-calibration.${device}.log # &
done

