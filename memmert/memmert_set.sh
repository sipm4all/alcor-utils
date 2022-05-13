#! /usr/bin/env bash

if [ -z $1 ] || [ -z $2 ]; then
    echo " usage: memmert_set.sh [device] [temperature] "
    exit 1
fi

DEVICE=$1
TEMPERATURE=$2

./memmert_cmd.sh $DEVICE OUT_SP_11_$TEMPERATURE
