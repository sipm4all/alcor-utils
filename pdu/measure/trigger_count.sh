#! /usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo " usage: $0 [device] [sleep] "
    exit 1
fi
device=$1
sleep=$2

reg="/au/readout/bin/register --connection ${AU_IPBUS_CONNECTIONS} --device ${device}"
blo="/au/readout/bin/block --connection ${AU_IPBUS_CONNECTIONS} --device ${device}"

$reg --node regfile.mode --write 0x0 > /dev/null
$reg --node regfile.mode --write 0x1 > /dev/null
$reg --node trigger_info.fifo_reset --write 1 > /dev/null
$reg --node regfile.mode --write 0x3 > /dev/null

sleep $sleep

$reg --node regfile.mode --write 0x1 > /dev/null
$reg --node regfile.mode --write 0x0 > /dev/null

nwords=$(${reg} --node trigger_info.fifo_occupancy | awk {'print $3'})
nwords=$(( nwords & 0xFFFF ))
sum=$(( sum + nwords ))
echo $(( sum / 2 ))
[[ $nwords == "0" ]] && return;
${blo} --node trigger_info.fifo_data --size ${nwords} > /tmp/trigger.dat
