#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 [device] "
    exit 1
fi
device=$1

telegram_message.sh "requested STOP of run ${devices}"

/au/pdu/measure/interprocess.sh $device "0x3f9 0x0"
