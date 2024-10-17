#! /usr/bin/env bash

if [ "$#" -ne 8 ]; then
    echo " usage: $0 [device] [chip] [channel] [vth] [offset] [threshold] [timer] [integrated] "
    exit 1
fi
DEVICE=$1
CHIP=$2
CHANNEL=$3
VTH=$4
OFFSET=$5
THRESHOLD=$6
TIMER=$7
INTEGRATED=$8

OPMODE=1

OUTPUT_PREFIX="/home/eic/DATA/tmp/ureadout.test"
OUTPUT_TAGNAME="${OUTPUT_PREFIX}.chip_${CHIP}.channel_${CHANNEL}"

echo " --- running ureadout: device ${DEVICE} chip-${CHIP} channel ${CHANNEL} "
echo "     spill timer: ${TIMER} clock cycles "
echo "     integrated time: ${INTEGRATED} seconds "

### collect data
echo " --- ureadout: /tmp/ureadout.test "
UREADOUT_TIMER=312500   # 10 ms
/au/readout/bin/ureadout --connection /etc/drich/drich_ipbus_connections.xml \
			 --device $DEVICE \
			 --output $OUTPUT_PREFIX \
			 --chip $CHIP \
			 --channel $CHANNEL \
			 --max_resets 10 \
			 --timer $TIMER \
			 --integrated $INTEGRATED \
			 --opmode $OPMODE \
			 --noinit \
			 --range 2 \
			 --vth $VTH \
			 --offset $OFFSET \
			 --threshold $THRESHOLD

### decode, analyse and finalise
echo " --- decode and analyse: $OUTPUT_TAGNAME "
/au/readout/bin/decoder --input $OUTPUT_TAGNAME.alcor.dat --output $OUTPUT_PREFIX.root

root -b -q -l "${ALCOR_DIR}/measure/2023-characterisation/ureadout_dcr_analysis.C(\"${OUTPUT_PREFIX}.root\", \"${OUTPUT_PREFIX}.dcr.root\")" 
