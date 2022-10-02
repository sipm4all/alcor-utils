#! /usr/bin/env bash

### standard measurement settings
export AU_BIAS_VOLTAGES="0"  # [V]
export AU_DELTA_THRESHOLDS="5"
export AU_INTEGRATED="0.1"
export AU_REPEAT=25
export AU_REPEAT=4

###
### HAMA1 scan values
###
HAMA1_EVEN_BIAS_VOLTAGES="51 53"
HAMA1_EVEN_SCAN_BIAS_VOLTAGES=$(seq 48 0.5 58 | tr "\n" " ")
HAMA1_ODD_BIAS_VOLTAGES="53 55"
HAMA1_ODD_SCAN_BIAS_VOLTAGES=$(seq 48 0.5 60 | tr "\n" " ")

###
### HAMA2 scan values
###
HAMA2_EVEN_BIAS_VOLTAGES="39 41"
HAMA2_EVEN_SCAN_BIAS_VOLTAGES=$(seq 36 0.5 43 | tr "\n" " ")
HAMA2_ODD_BIAS_VOLTAGES="41 43"
HAMA2_ODD_SCAN_BIAS_VOLTAGES=$(seq 36 0.5 45 | tr "\n" " ")

###
### FBK scan values
###
FBK_EVEN_BIAS_VOLTAGES="33 35"
FBK_EVEN_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 38 | tr "\n" " ")
FBK_ODD_BIAS_VOLTAGES="35 37"
FBK_ODD_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 40 | tr "\n" " ")

###
### SENSL scan values
###
SENSL_EVEN_BIAS_VOLTAGES="28.5 30.5"
SENSL_EVEN_SCAN_BIAS_VOLTAGES=$(seq 23.5 0.5 32.5 | tr "\n" " ")
SENSL_ODD_BIAS_VOLTAGES="26.5 28.5"
SENSL_ODD_SCAN_BIAS_VOLTAGES=$(seq 23.5 0.5 32.5 | tr "\n" " ")

### scans to be performed
export AU_SCANS="vbias"

### scan settings
export AU_SCAN_BIAS_VOLTAGES=$SENSL_EVEN_SCAN_BIAS_VOLTAGES
export AU_SCAN_THRESHOLDS=$(seq 0 1 63 | tr "\n" " ")
export AU_CARRIER="sensl"

chip="3"
erows="A C E G"
cols="1 2 3 4"
for row in $erows; do
    for col in $cols; do
	time -p /au/measure/readout-box/dcr_scan.sh vbias ${chip} ${row}${col}
    done
done

### scan settings
export AU_SCAN_BIAS_VOLTAGES=$SENSL_ODD_SCAN_BIAS_VOLTAGES
export AU_SCAN_THRESHOLDS=$(seq 0 1 63 | tr "\n" " ")
export AU_CARRIER="sensl"

chip="3"
orows="B D F H"
cols="1 2 3 4"
for row in $orows; do
    for col in $cols; do
	time -p /au/measure/readout-box/dcr_scan.sh vbias ${chip} ${row}${col}
    done
done
