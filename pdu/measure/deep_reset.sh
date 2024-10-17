#! /usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo " usage: $0 [device] [chip] [lane] "
    exit 1
fi
device=$1
chip=$2
lane=$3

reg="/au/readout/bin/register --connection ${AU_IPBUS_CONNECTIONS} --device ${device}"
blo="/au/readout/bin/block --connection ${AU_IPBUS_CONNECTIONS} --device ${device}"

main()
{
    ### reset and sleep a bit
    mode 0x0
    echo " deep reset "
    deep_reset
}

download()
{
    rm -f $1
    while true; do
	### read FIFO occupancy
	nwords=$(${reg} --node alcor_readout_id${chip}_lane${lane}.fifo_occupancy | awk {'print $3'})
	nwords=$(($nwords & 0xFFFF))
	echo " --- there are $nwords words in the FIFO "
	[[ $nwords == "0" ]] && break;
	${blo} --node alcor_readout_id${chip}_lane${lane}.fifo_data --size ${nwords} >> $1
    done
    echo " --- downloaded data: $1 "
}

mode()
{
    ${reg} --node regfile.mode --write $1
}

filter()
{
    if [ "$1" == "on" ]; then
	${reg} --node alcor_controller_id${chip} --write 0x0330000f
	${reg} --node alcor_controller_id${chip}
    elif [ "$1" == "off" ]; then
	${reg} --node alcor_controller_id${chip} --write 0x03300000
	${reg} --node alcor_controller_id${chip}
    fi
}

reset()
{
    ${reg} --node alcor_readout_id${chip}_lane${lane}.fifo_reset --write 1
}

deep_reset()
{
    echo " --- deep_reset "
    while true; do
	### read FIFO occupancy
	nwords=$(${reg} --node alcor_readout_id${chip}_lane${lane}.fifo_occupancy | awk {'print $3'})
	nwords=$(($nwords & 0xFFFF))
	echo " --- there are $nwords words in the FIFO "	
	[[ $nwords == "0" ]] && break;
	${reg} --node alcor_readout_id${chip}_lane${lane}.fifo_reset --write 1
    done
}

main
