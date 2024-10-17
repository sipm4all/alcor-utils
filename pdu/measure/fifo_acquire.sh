#! /usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo " usage: $0 [device] [chip] [sleep] "
    exit 1
fi
device=$1
chip=$2
sleep=$3

reg="/au/readout/bin/register --connection ${AU_IPBUS_CONNECTIONS} --device ${device}"
blo="/au/readout/bin/block --connection ${AU_IPBUS_CONNECTIONS} --device ${device}"

main()
{

    ### run sequence
    mode 0x0                       # run OFF
    filter $chip on                # filter
    mode 0x1                       # run ON
    for lane in {0..3}; do
	reset $chip $lane          # reset FIFO
    done
    mode 0x3                       # spill ON
    sleep $sleep                   # sleep
    mode 0x1                       # spill OFF
    mode 0x0                       # run OFF

    ### download data
    for lane in {0..3}; do
	download $chip $lane /tmp/data.chip${chip}.lane${lane}.dat
    done
}

download()
{
    chip=$1
    lane=$2
    name=$3
    rm -f $name
    while true; do
	### read FIFO occupancy
	nwords=$(${reg} --node alcor_readout_id${chip}_lane${lane}.fifo_occupancy | awk {'print $3'})
	nwords=$(($nwords & 0xFFFF))
	echo " --- there are $nwords words in the FIFO "
	[[ $nwords == "0" ]] && break;
	${blo} --node alcor_readout_id${chip}_lane${lane}.fifo_data --size ${nwords} >> $name
    done
    echo " --- downloaded data: $name "
}

mode()
{
    ${reg} --node regfile.mode --write $1
}

filter()
{
    chip=$1
    value=$2
    if [ "$value" == "on" ]; then
	${reg} --node alcor_controller_id${chip} --write 0x0330000f
	${reg} --node alcor_controller_id${chip}
    elif [ "$value" == "off" ]; then
	${reg} --node alcor_controller_id${chip} --write 0x03300000
	${reg} --node alcor_controller_id${chip}
    fi
}

reset()
{
    chip=$2
    lane=$2
    ${reg} --node alcor_readout_id${chip}_lane${lane}.fifo_reset --write 1
}

main
