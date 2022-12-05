#! /usr/bin/bash

number=$1
name=$2
volts=$3
what=$4

name=${name,,}

dac=$(/au/masterlogic/hvcalib/hvcalib-malaguti.sh $name $volts | grep dac | awk {'print $2'})

if [ $what == "all" ]; then
    /au/masterlogic/set $number $dac
elif [ $what == "even" ]; then
    /au/masterlogic/set_dac12 $number 0 $dac
    /au/masterlogic/set_dac12 $number 2 $dac
    /au/masterlogic/set_dac12 $number 4 $dac
    /au/masterlogic/set_dac12 $number 6 $dac    
elif [ $what == "odd" ]; then
    /au/masterlogic/set_dac12 $number 1 $dac
    /au/masterlogic/set_dac12 $number 3 $dac
    /au/masterlogic/set_dac12 $number 5 $dac
    /au/masterlogic/set_dac12 $number 7 $dac    
elif [[ $what == "ch-"[0-7] ]]; then
    channel=${what: -1}
    /au/masterlogic/set_dac12 $number $channel $dac
fi
