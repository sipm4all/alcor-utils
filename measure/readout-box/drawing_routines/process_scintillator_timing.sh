#! /usr/bin/env bash

for I in alcdaq.*.miniframe.root; do
    root -b -q -l "scintillator_timing.C(\"$I\")"
done

hadd -f scintillator_timing.alcdaq.miniframe.root scintillator_timing.alcdaq.*.miniframe.root 
