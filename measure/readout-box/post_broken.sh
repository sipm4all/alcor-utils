#! /usr/bin/env bash

chip=$1
lane=$2
data="readout_monitor,source=broken_lane,chip=$chip,lane=$lane value=1"
curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null



