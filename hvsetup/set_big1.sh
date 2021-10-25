#! /usr/bin/env bash

DEVNUM=28
[ -z $1 ] && exit 1
echo " setting current on BIG1 Peltier: $1 "
./tti.py $DEVNUM 16 $1 1
