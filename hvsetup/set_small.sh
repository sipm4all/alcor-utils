#! /usr/bin/env bash

DEVNUM=25
[ -z $1 ] && exit 1
echo " setting current on SMALL Peltier: $1 "
./tti.py $DEVNUM 2 $1 1
