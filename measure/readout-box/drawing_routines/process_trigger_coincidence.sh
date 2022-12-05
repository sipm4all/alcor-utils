#! /usr/bin/env bash

for I in alcdaq.*.miniframe.root; do
    root -b -q -l "trigger_coincidence.C(\"$I\", 0., 0.)"
done

hadd -f trigger_coincidence.alcdaq.miniframe.root trigger_coincidence.alcdaq.*.miniframe.root 
