#! /usr/bin/env bash

DEVICE="/dev/PHYMOTION"

x=$(/au/phymotion/cmd.py --device ${DEVICE} --cmd "1.1P20R?" | sed -n "2 p")
y=$(/au/phymotion/cmd.py --device ${DEVICE} --cmd "2.1P20R?" | sed -n "2 p")

echo "${x} ${y}"
