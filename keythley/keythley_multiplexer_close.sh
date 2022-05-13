#! /usr/bin/env bash

/au/keythley/keythley_multiplexer_cmd.py "ROUTE:OPEN:ALL"
board=$1
channel=$2
CH=$(/au/keythley/keythley_multiplexer_map.py $channel)
/au/keythley/keythley_multiplexer_cmd.py "ROUTE:CLOSE (@$board$CH)"
/au/keythley/keythley_multiplexer_cmd.py "ROUTE:CLOSE?"
