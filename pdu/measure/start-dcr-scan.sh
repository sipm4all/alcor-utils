#! /usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "usage: $0 [device] [setup]"
    exit 1
fi
name=$1
setup=$2

runname=$(date +%Y%m%d-%H%M%S)
devices=$(awk '$1 !~ /^#/' ${AU_READOUT_CONFIG} | awk {'print $4'} | sort | uniq | tr '\n' ' ')

telegram_message.sh "requested DCR scan: ${runname} ${name}"

### ALCOR init one at a time
#for device in $devices; do
#    [[ $name != "all" ]] && [[ $name != $device ]] && continue
#    echo " --- running alcor init: /au/pdu/control/alcorInit.sh ${device} 0 /tmp"
#    ln -sf /au/pdu/conf/readout.${device}.baseline.conf /au/pdu/conf/readout.${device}.conf
#    /au/pdu/control/alcorInit.sh ${device} 0 /tmp &> /tmp/alcorInit.${device}.log
#done

### scan all in parallel
for device in $devices; do
    [[ $name != "all" ]] && [[ $name != $device ]] && continue
    echo " --- running dcr scan: /au/pdu/measure/run-dcr-setup.sh ${runname} ${device} ${setup}"
    /au/pdu/measure/run-dcr-setup.sh ${runname} ${device} ${setup} &> /tmp/run-dcr-setup.${device}.log
done

wait
telegram_message.sh "DCR scan completed, good day"
