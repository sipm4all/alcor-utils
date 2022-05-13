#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [chip] [xy_channel]"
    exit 1
fi

chip=$1
xy_channel=$2
eo_channel=$(/au/readout/python/mapping.py --xy2eo $xy_channel)

pcrfile=$(/au/measure/alcor_fast_init.sh $chip $eo_channel | grep "Loading PCR file" | awk '{print $4}')
threshold=$(awk -v ch=$eo_channel '$1 == ch' $pcrfile | awk '{print $5}')

echo $threshold


