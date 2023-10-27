#! /usr/bin/env bash

if [ "$#" -ne 4 ]; then
    echo " usage: $0 [device] [chip] [lane] [sleep] "
    exit 1
fi
device=$1
chip=$2
lane=$3
sleep=$4

reg="/au/readout/bin/register --connection /etc/drich/drich_ipbus_connections.xml --device ${device}"
blo="/au/readout/bin/block --connection /etc/drich/drich_ipbus_connections.xml --device ${device}"

main()
{

    ### run sequence
    mode 0x0       # run OFF
    filter on     # filter
    mode 0x1       # run ON
    reset          # reset FIFO
    mode 0x3       # spill ON
    echo " --- sleep $sleep seconds "
    sleep $sleep   # sleep
    mode 0x1       # spill OFF
    mode 0x0       # run OFF

    ### read FIFO time
    timer=$(${reg} --node alcor_readout_id${chip}_lane${lane}.fifo_timer | awk {'print $3'})
    hex=${timer:2}
    dec=$((16#$hex))
    nsec=$(echo "$dec / 31250000." | bc -l)
    echo " --- the timer is $timer: $nsec seconds  "

    ### download data
    download /tmp/data.dat
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

main
