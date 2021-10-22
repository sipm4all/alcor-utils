#! /usr/bin/env bash

if [ -z $1 ]; then
    echo " usage: ./draw_lanechannel [directory] "
    exit
fi
dir=$1

for chip in 0 1 2 3 4; do
for channel in {0..31}; do
    root -b -q -l "${ALCOR_DIR}/readout/macros/draw_lanechannel.C(\"$dir\", $chip, $channel, {\"hvzero\", \"vover3\"})" &
done
wait
done
mkdir -p $dir/PNG
mv $dir/*.png $dir/PNG/.

