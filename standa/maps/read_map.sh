#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ] || [ -x $3 ]; then
    echo "usage: $0 [map] [chip] [xy_channel]"
    exit 1
fi

mapname=$1
chip=$2
xy_channel=$3

awk -v chip=$chip -v xy_channel=$xy_channel '$1 == chip && $2 == xy_channel' $mapname | awk '{print $3, $4}'
