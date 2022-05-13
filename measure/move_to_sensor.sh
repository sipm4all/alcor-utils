#! /usr/bin/env bash

STANDAMAP="/au/standa/maps/20220206/standa_map_extra.dat"

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [chip] [xy_channel]"
    exit 1
fi

CHIP=$1
CHANNEL=$2

paused()
{
    ### check if paused
    while [ -f .pause ]; do
	echo " $0: paused"
	sleep 1
    done
}

if [ -z "$AU_DRYRUN" ]; then

    ### check if we are there already
    curpos=$(/au/standa/gpos)
    moveto=$(/au/standa/maps/read_map.sh $STANDAMAP $CHIP $CHANNEL)
    if [ "$curpos" == "$moveto" ]; then
	echo " --- already at destination, no need to move "
	exit
    fi
    paused

    ### change temperature to T = +20 C and wait until we are stable
    while ! (/au/memmert/set --temp 20); do
	echo " --- failed to set memmert to T = +20 C"
	sleep 1;
    done
    paused
    /au/memmert/wait --delta 2 --time 1800 --sleep 5
    paused
    
    ### move to sensor centre
    /au/standa/unlock
    /au/standa/home
    /au/standa/move $(/au/standa/maps/read_map.sh $STANDAMAP $CHIP $CHANNEL)
    /au/standa/lock
    paused
    
    ### change temperature to T = -30 C and wait until we are stable
    while ! (/au/memmert/set --temp -30); do
	echo " --- failed to set memmert to T = -30 C"
	sleep 1;
    done
    paused
    /au/memmert/wait --delta 2 --time 1800 --sleep 5
    paused
    
fi
