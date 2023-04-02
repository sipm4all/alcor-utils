#! /usr/bin/env bash

mapping=("F3" "F1" "E3" "E1" "G1" "G3" "H1" "H3" "G2" "G4" "H2" "H4" "F4" "F2" "E4" "E2" "C2" "C4" "D2" "D4" "B4" "B2" "A4" "A2" "B3" "B1" "A3" "A1" "C1" "C3" "D1" "D3")

chip=$1
lane=$2
#echo "$chip | $lane"
thedata=""
for ch in {0..7}; do
    channel=$((ch + 8 * lane))
    channel=${mapping[$channel]}
#    channel=$(/au/readout/python/mapping.py --eo2xy $channel)
    ch=$((ch+3))
    rate=${!ch}
    data="rate_monitor,chip=$chip,channel=$channel value=$rate"
#    thedata="$thedata $data\n"
#    echo $data
    curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null
done

#curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$thedata" &> /dev/null

if [ "$chip" -eq "4" ]; then
    sleep 1
    /au/measure/readout-box/readout_system_monitor.sh
fi
