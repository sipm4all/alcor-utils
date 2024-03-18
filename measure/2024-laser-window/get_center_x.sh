#! /usr/bin/env bash

if [ $# -ne 2 ]; then
    echo " usage: $0 [what] [channel] "
    exit 1
fi
what=$1
channel=$2
cat /au/measure/2024-laser-window/centers.txt | grep ${what} | grep ${channel} | awk {'print $3'}
