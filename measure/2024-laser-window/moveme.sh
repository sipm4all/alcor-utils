#! /usr/bin/env bash

declare -A pos
pos[0]="0 0"
pos[1]="-0.75 -0.75"
pos[2]="-0.75 +0.75"
pos[3]="+0.75 +0.75"
pos[4]="+0.75 -0.75"

center_x="-89.5"
center_y="-45.2"

dy=0
for dx in $(seq -2 0.1 2); do
    x=$(python -c "print ${center_x} + ${dx}")
    y=$(python -c "print ${center_y} + ${dy}")
    echo ${x} ${y}
done
