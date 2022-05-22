#! /usr/bin/env bash

if [ -x $1 ]; then
    echo " usage: $0 [vbias]"
    exit 1
fi

vbias=$1
res="54.900"

### get DAC value
dac=$(python -c "print(int(round(1000 * ${vbias} / ( (1000 / ${res} ) + 1 ))))")

### print output
echo " vbias: ${vbias} "
echo "   dac: ${dac} "
