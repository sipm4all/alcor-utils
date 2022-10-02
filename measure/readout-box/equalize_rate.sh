#! /usr/bin/env bash

chip="0"
row="A"
cols="1 2 3 4"

min_average=999999999
min_channel=XX
for col in $cols; do
    sum=0
    ncounts=0
    channel=$row$col
    for I in {1..10}; do
	rate=$(/au/measure/rate.sh $chip $channel | awk {'print $15'})
	sum=$(echo "$sum + $rate" | bc)
	ncounts=$((ncounts + 1))
#	echo "$rate $sum $ncounts"
    done
    average=$(echo "$sum / $ncounts" | bc)
    echo "$channel: $average"
    if [ "$average" -lt "$min_average" ]; then
	min_average=$average
	min_channel=$channel
    fi
done
echo "minimum rate: $min_average"
if [ "$min_average" -lt "20000" ]; then
    echo " lower than 20 k, must increase Vbias "
else
    echo " higher than 20 k, must increase Vbias "
fi
