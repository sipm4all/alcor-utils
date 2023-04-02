#! /usr/bin/env bash

chips="0 1 2 3"
chips="0"

rows="A B C D E F G H"
cols="1 2 3 4"

#rows=H
#cols=1

while true; do
    /au/control/alcorInit.sh 0 /tmp/ true &> .alcorInit.log
    for chip in $chips; do
	for row in $rows; do
	    for col in $cols; do

		channel=$row$col
		eo_channel=$(/au/readout/python/mapping.py --xy2eo $channel)
		rate=$(/au/readout/bin/rate --connection /au/etc/connection2.xml --chip $chip --channel $eo_channel --delta_threshold 5 | awk {'print $15'})

		if [[ $? -ne 0 ]]; then
		    echo "chip broken"
		fi
		
		data="rate_monitor,chip=$chip,channel=$channel value=$rate"
		echo $data
		curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data"
	    done
	done
    done
done
