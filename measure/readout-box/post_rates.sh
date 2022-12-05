#! /usr/bin/env bash

chip=$1
lane=$2
echo "$chip | $lane"
for ch in {0..7}; do
    channel=$((ch + 8 * lane))
    channel=$(/au/readout/python/mapping.py --eo2xy $channel)
    ch=$((ch+3))
    rate=${!ch}
    data="rate_monitor,chip=$chip,channel=$channel value=$rate"
    echo $data
    curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null
done

exit 1

