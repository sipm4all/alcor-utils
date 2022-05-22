#! /usr/bin/env bash

if [ -x $1 ]; then
    echo " usage: hvcalib-bo-fbk.sh [temperature] [vref]"
    exit 1
fi

tset="$1"  # destination temperature [C]

### SiPM reference parameters

tref="24." # reference temperature [C]
tcoe="35." # temperature coefficient [mV]
vref="35." # vbias at reference temperature [V]

if [ ! -x $2 ]; then
    vref=$2
fi

### DAC calibration parameters
p0="-0.694637"
p1="51.9306"

### get vbias at set temperature 
vbias=$(echo "${vref} + ${tcoe} * 0.001 * (${tset} - ${tref})" | bc -l)

### get DAC value
dac=$(echo "${p0} + ${p1} * ${vbias}" | bc -l)
dac=$(echo "scale=0; (${dac} + 0.5) / 1" | bc -l)

### print output
echo " vbias: ${vbias} "
echo "   dac: ${dac} "
