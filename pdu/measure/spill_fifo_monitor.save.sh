#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo " usage: $0 [device] "
    exit 1
fi
device=$1

reg="/au/readout/bin/register --connection ${AU_IPBUS_CONNECTIONS} --device ${device}"
blo="/au/readout/bin/block --connection ${AU_IPBUS_CONNECTIONS} --device ${device}"

$reg --node regfile.mode --write 0x0 > /dev/null
$reg --node regfile.mode --write 0x1 > /dev/null
$reg --node regfile.mode --write 0x5 > /dev/null
$reg --node trigger_info.fifo_reset --write 1 > /dev/null

sum=0
while true; do
    nwords=$(${reg} --node trigger_info.fifo_occupancy | awk {'print $3'})
    nwords=$(($nwords & 0xFFFF))
    sum=$(( sum + nwords ))
    mod=$((sum % 4))
    if [ $nwords !=  0 ]
    then
        data=$(${reg} --node trigger_info.fifo_data)
    	echo $data
    fi
    echo "$((sum/4))"
    [[ $nwords == "0" ]] && continue;
    ${blo} --node trigger_info.fifo_data --size ${nwords} > /dev/null
done
