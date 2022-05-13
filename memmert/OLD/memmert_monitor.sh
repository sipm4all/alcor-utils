#! /usr/bin/env bash

DEVICE=/dev/ttyUSB0

### read set point values
ST=$(./memmert_cmd.sh $DEVICE IN_SP_11 | tr -d "\r\n")

### read actual values
T1=$(./memmert_cmd.sh $DEVICE IN_PV_11 | tr -d "\r\n")
RH=$(./memmert_cmd.sh $DEVICE IN_PV_13 | tr -d "\r\n")
#T2=$(./memmert_cmd.sh $DEVICE IN_PV_15)
#T3=$(./memmert_cmd.sh $DEVICE IN_PV_1B)
#T4=$(./memmert_cmd.sh $DEVICE IN_PV_1C)

echo $(date +%s) $ST $T1 $RH
