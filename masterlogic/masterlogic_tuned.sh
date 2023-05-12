#! /usr/bin/env bash

if [ "$#" != "4" ]; then
    echo "usage: $0 [board] [type] [dac12] [dac8]"
    exit 1
fi

board=$1
name=$2
dac12=$3
dac8=$4

name=${name,,}

while read p; do
    channel=$(echo $p | awk {'print $1'})
    volts=$(echo $p | awk {'print $2'})
    dac=$(/au/masterlogic/hvcalib/hvcalib-malaguti.sh $name $volts | grep dac | awk {'print $2'})
    echo "/au/masterlogic/set_dac12 $board $channel $dac"
    /au/masterlogic/set_dac12 $board $channel $dac
done < $dac12

while read p; do
    channel=$(echo $p | awk {'print $1'})
    value=$(echo $p | awk {'print $2'})
    value=$(echo "scale=0; ($value * 1000) / 1" | bc)
    echo "/au/masterlogic/masterlogic_client.py --ml $board --cmd \"T $channel $value\""
    timeout 30 /au/masterlogic/masterlogic_client.py --ml $board --cmd "T $channel $value "
done < $dac8
