#! /usr/bin/env bash

DEVICE="/dev/PHYMOTION"

if [ "$#" -ne 2 ]; then
    echo " usage: $0 [mm_x] [mm_y] "
    exit 1
fi
x=$1
y=$2

echo " --- moving to: ${x} ${y} "
/au/phymotion/cmd.py --device ${DEVICE} --cmd "1.1A${x}"
/au/phymotion/cmd.py --device ${DEVICE} --cmd "2.1A${y}"
/au/phymotion/wait.sh
pos=$(/au/phymotion/gpos.sh)
echo " --- moved to: ${pos} "
