#! /usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "usage: $0 [run-name] [name] [nspills]"
    exit 1
fi
runname=$1
name=$2
nspill=$3

export DRICH_READOUT_NSPILL=$nspill

outputdir=/home/eic/DATA/2024-testbeam/actual/physics/$runname
mkdir -p $outputdir/conf
cp /etc/drich/drich_kc705.conf $outputdir/conf/.
cp ${AU_READOUT_CONFIG} $outputdir/conf/.
cp /etc/drich/drich_trigger.conf $outputdir/conf/.
ln -nsf $outputdir /home/eic/DATA/2024-testbeam/actual/physics/latest

readout_devices=$(awk '$1 !~ /^#/' ${AU_READOUT_CONFIG} | awk {'print $4'} | sort | uniq | tr '\n' ' ')
trigger_devices=$(awk '$1 !~ /^#/' /etc/drich/drich_trigger.conf | awk {'print $2'} | sort | uniq | tr '\n' ' ')
devices=$(echo $readout_devices $trigger_devices | tr ' ' '\n' | sort | uniq | tr '\n' ' ')

for device in $devices; do
    [[ $name != "all" ]] && [[ $name != $device ]] && continue
    echo " --- starting $device device readout processes: /au/pdu/measure/start-device-readout-processes.sh ${runname} ${device}"
    /au/pdu/measure/start-device-readout-processes.sh ${runname} ${device} &> /tmp/start-device-readout-processes.${device}.log & 
done
wait

