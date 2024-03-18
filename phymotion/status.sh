#! /usr/bin/env bash

DEVICE="/dev/PHYMOTION"

echo " --- axis 1 "
/au/phymotion/cmd.py --device ${DEVICE} --cmd "SE1.1?"
echo " --- axis 2 "
/au/phymotion/cmd.py --device ${DEVICE} --cmd "SE2.1?"
