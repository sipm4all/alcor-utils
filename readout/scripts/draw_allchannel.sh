#! /usr/bin/env bash

if [ -z $1 ]; then
    echo " usage: ./draw_allchannel [directory] [tag]"
    exit
fi
dir=$1

if [ -z $2 ]; then
    echo " usage: ./draw_allchannel [directory] [tag]"
    exit
fi
tag=$2

for chip in {0..5}; do
    root -b -q -l "${ALCOR_DIR}/readout/macros/draw_allchannel.C(\"$dir\", $chip, {\"$tag\"})" &
done
mkdir -p $dir/PNG
mv $dir/*.png $dir/PNG/.
