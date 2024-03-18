#! /usr/bin/env bash

DEVICE="/dev/PHYMOTION"

echo " --- homing "
/au/phymotion/cmd.py --device ${DEVICE} --cmd "1.1R+"
/au/phymotion/cmd.py --device ${DEVICE} --cmd "2.1R+"
/au/phymotion/wait.sh
pos=$(/au/phymotion/gpos.sh)
echo " --- homed "
