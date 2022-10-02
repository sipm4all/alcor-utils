#! /usr/bin/env bash

chip=$1
lane=$2
npolls=$3
occ=$4
bytes=$5

echo $@

data="readout_monitor,chip=$chip,lane=$lane,name=npolls value=$npolls"
curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null

data="readout_monitor,chip=$chip,lane=$lane,name=max_occupancy value=$occ"
curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null

data="readout_monitor,chip=$chip,lane=$lane,name=integrated_bytes value=$bytes"
curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null

exit 1

