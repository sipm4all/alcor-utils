#! /usr/bin/env bash

DEVICE="/dev/PHYMOTION"

sleep 0.5

while /au/phymotion/cmd.py --device ${DEVICE} --cmd "SE1.1?" | grep running > /dev/null; do
    sleep 0.5
done

while /au/phymotion/cmd.py --device ${DEVICE} --cmd "SE2.1?" | grep running > /dev/null; do
    sleep 0.5
done

