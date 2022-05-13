#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [chip] [channel]"
    exit 1
fi
CHIP=$1
CHANNEL="$2"

VOLTAGES=$(seq 800 5 1100) # [mV]
VOLTAGES=$(seq 940 5 1010) # [mV]

TAGNAME="chip${CHIP}-${CHANNEL}"
FILENAME="${TAGNAME}.vpulse_scan.fine.dat"

REPEAT=100

rm -rf $FILENAME
for VOLTAGE in $VOLTAGES; do

    /au/pulser/set --voltage $VOLTAGE
    
    for i in $(seq 1 $REPEAT); do
	OUTPUT=$(/au/measure/pulser_rate.sh $CHIP $CHANNEL)
	echo "pulse_voltage = $VOLTAGE $OUTPUT" | tee -a $FILENAME
    done
    
done

/au/measure/tree.sh $FILENAME pulse_voltage counts_on counts_off period_on period_off rate_on rate_off

