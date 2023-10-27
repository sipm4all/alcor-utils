#! /usr/bin/env bash

for filein in $(grep baseline-calibration readout.kc705-*.run.conf | awk {'print $5'}); do
    /au/readout/python/updatePCR.py --filein pcr/${filein}.pcr --opmode 4 > pcr/${filein}.tot.pcr
done
