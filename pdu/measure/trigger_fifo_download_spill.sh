#! /usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo " usage: $0 [device] [sleep] "
    exit 1
fi
device=$1
sleep=$2

reg="/au/readout/bin/register --connection ${AU_IPBUS_CONNECTIONS} --device ${device}"
blo="/au/readout/bin/block --connection ${AU_IPBUS_CONNECTIONS} --device ${device}"

main()
{

    ### run sequence
    mode 0x0       # run OFF
    mode 0x1       # run ON
    reset          # reset FIFO
    mode 0x5       # spill ON
    echo " --- sleep $sleep seconds "
    sleep $sleep   # sleep
    mode 0x1       # spill OFF
    mode 0x0       # run OFF

    ### download data
    download /tmp/data.dat
}

download()
{
    rm -f $1
    while true; do
	### read FIFO occupancy
	nwords=$(${reg} --node trigger_info.fifo_occupancy | awk {'print $3'})
	nwords=$(($nwords & 0xFFFF))
	echo " --- there are $nwords words in the FIFO "
	[[ $nwords == "0" ]] && break;
	${blo} --node trigger_info.fifo_data --size ${nwords} >> $1
    done
    echo " --- downloaded data: $1 "
}

mode()
{
    ${reg} --node regfile.mode --write $1
}

reset()
{
    ${reg} --node trigger_info.fifo_reset --write 1
}

main
