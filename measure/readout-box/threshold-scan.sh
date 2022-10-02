#! /usr/bin/env bash

### standard measurement settings
export AU_BIAS_VOLTAGES="26.4"  # [V]
export AU_BIAS_VOLTAGES="39."  # [V]
export AU_DELTA_THRESHOLDS="3"
export AU_INTEGRATED="0.1"
export AU_REPEAT=100
export AU_REPEAT=25
#export AU_REPEAT=4

### scan settings
export AU_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 38 | tr "\n" " ") # [V]
export AU_SCAN_THRESHOLDS=$(seq 0 1 63 | tr "\n" " ")

### scans to be performed
export AU_SCANS="threshold"

### carrier
export AU_CARRIER="hama2"

### uncomment for manual bias
#export AU_BIAS_MANUAL="false"

chips="2 3"
rows="A B C D E F G H"
cols="1 2 3 4"

chip="2"
rows="A"
cols="1 2 3 4"

for chip in $chip; do
    for row in $rows; do
	for col in $cols; do
	    time -p /au/measure/2022-characterisation/dcr_scan.sh threshold ${chip} ${row}${col}
	done
    done
done
