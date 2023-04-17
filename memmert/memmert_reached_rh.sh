#! /usr/bin/env bash

while (( $(echo "$(/au/memmert/get --rh | grep humidity | awk {'print $3'}) > $1" | bc -l) )); do
    echo " --- memmert did not reach RH = $1 %"
    sleep 60s
done
echo " --- memmert reached RH = $1 %"
