#! /usr/bin/env bash

DEVNUM=102
[ -z $1 ] && exit 1
echo " setting current on BIG0 Peltier: $1 "
./tti.py $DEVNUM 16 $1 1
