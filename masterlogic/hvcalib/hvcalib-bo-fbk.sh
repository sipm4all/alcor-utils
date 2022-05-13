#! /usr/bin/env bash

### DAC calibration parameters
p0="-0.694637"
p1="51.9306"

if [ -x $1 ]; then
    echo " usage: $0 [vbias]"
    exit 1
fi

### get vbias at set temperature 
vbias=$1

### get DAC value
dac=$(echo "${p0} + ${p1} * ${vbias}" | bc -l)
dac=$(echo "scale=0; (${dac} + 0.5) / 1" | bc -l)

### print output
echo " vbias: ${vbias} "
echo "   dac: ${dac} "
