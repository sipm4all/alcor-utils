#! /usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "usage: $0 [ip] [sleep]"
    exit 1
fi
ip=$1
sleep=$2

seconds=$(/au/pdu/measure/fifo_download.sh $ip 0 0 $sleep | grep "the timer is" | awk {'print $6'})
rollovers=$(grep 5c5c5c5c /tmp/data.dat | wc -l)
frequency=$(echo "32768 * $rollovers / $seconds * 0.0000001" | bc)
echo $frequency MHz
