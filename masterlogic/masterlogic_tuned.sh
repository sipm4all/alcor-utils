#! /usr/bin/env bash

if [ "$#" != "4" ]; then
    echo "usage: $0 [board] [type] [dac12] [dac8]"
    exit 1
fi

board=$1
type=$2
dac12=$3
dac8=$4

while read p; do
    channel=$(echo $p | awk {'print $1'})
    volts=$(echo $p | awk {'print $2'})
    dac=$(/au/masterlogic/hvcalib/hvcalib-malaguti.sh $type $volts | grep dac | awk {'print $2'})
    echo "/au/masterlogic/set_dac12 $board $channel $dac"
    /au/masterlogic/set_dac12 $board $channel $dac
done < $dac12

while read p; do
    channel=$(echo $p | awk {'print $1'})
    value=$(echo $p | awk {'print $2'})
    echo "timeout 1 /au/masterlogic/masterlogic_client.py --ml $board --cmd \"T $channel $value\""
    timeout 1 /au/masterlogic/masterlogic_client.py --ml $board --cmd "T $channel $value"
done < $dac8
