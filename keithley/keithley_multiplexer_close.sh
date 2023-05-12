#! /usr/bin/env bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo " usage: $0 [board] [channel] "
    exit 1
fi
board=$1
channel=$2

/au/keithley/keithley_multiplexer_open.sh
CH=$(/au/keithley/keithley_multiplexer_map.py $channel)
/au/keithley/keithley_multiplexer_cmd.py "ROUTE:CLOSE (@$board$CH)"
/au/keithley/keithley_multiplexer_status.sh
