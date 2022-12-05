#! /usr/bin/env bash

for I in alcdaq.*.miniframe.root; do
    root -b -q -l "scintillator_coincidence.C(\"$I\")"
done

hadd -f scintillator_coincidence.alcdaq.miniframe.root scintillator_coincidence.alcdaq.*.miniframe.root 
