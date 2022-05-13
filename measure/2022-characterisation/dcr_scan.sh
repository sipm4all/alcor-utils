#! /usr/bin/env bash

### input parameters
if [ -x $1 ] || [ -x $2 ] || [ -x $3 ]; then
    echo "usage: $0 [scan] [chip] [channel]"
    exit 1
fi
SCAN="$1"
CHIP="$2"
CHANNEL="$3"
EOCHANNEL=$(/au/readout/python/mapping.py --xy2eo $CHANNEL)
DOCHANNEL=$(/au/readout/python/mapping.py --xy2do $CHANNEL)
DAC12=$(echo "scale=0; $DOCHANNEL / 4" | bc -l)

echo " --- "
echo " --- running DCR $SCAN scan: chip $CHIP channel $CHANNEL "
echo " --- "
    
### sipm carrier
if [ -z "$AU_CARRIER" ]; then
    echo " --- AU_CARRIER undefined "
    exit 1
fi
CARRIER=${AU_CARRIER}

### sipm bias voltages [V]
if [ -z "$AU_BIAS_VOLTAGES" ]; then
    echo " --- AU_BIAS_VOLTAGES undefined "
    exit 1
fi
BIAS_VOLTAGES=${AU_BIAS_VOLTAGES}

### delta thresholds
if [ -z "$AU_DELTA_THRESHOLDS" ]; then
    echo " --- AU_DELTA_THRESHOLDS undefined "
    exit 1
fi
DELTA_THRESHOLDS=${AU_DELTA_THRESHOLDS}

### pulse_rate repetitions
if [ -z "$AU_REPEAT" ]; then
    echo " --- AU_REPEAT undefined "
    exit 1
fi
REPEAT=${AU_REPEAT}

### pulse_rate integrated
if [ -z "$AU_INTEGRATED" ]; then
    echo " --- AU_INTEGRATED undefined "
    exit 1
fi
INTEGRATED=${AU_INTEGRATED}
MIN_TIMER=$(bc -l <<< "scale=0; (32000000 * $INTEGRATED) / 1")

### change variables depending on scan type
case $SCAN in
    *vbias)
	if [ -z "$AU_SCAN_BIAS_VOLTAGES" ]; then
	    echo " --- AU_SCAN_BIAS_VOLTAGES undefined "
	    exit 1
	fi
	BIAS_VOLTAGES=${AU_SCAN_BIAS_VOLTAGES}
	THRESHOLDS=${DELTA_THRESHOLDS}
	THRESHOLD_SETTINGS="--delta_threshold"
	;;
    *threshold)
	if [ -z "$AU_SCAN_THRESHOLDS" ]; then
	    echo " --- AU_SCAN_THRESHOLDS undefined "
	    exit 1
	fi
	THRESHOLDS=${AU_SCAN_THRESHOLDS}
	THRESHOLD_SETTINGS="--threshold"
	;;
    *)
	echo " --- unknown scan type: ${SCAN} "
	exit 1
esac

### ready to start
DIRNAME="rate/${SCAN}_scan"
mkdir -p ${DIRNAME}
TAGNAME="chip${CHIP}-${CHANNEL}"
FILENAME="${DIRNAME}/${TAGNAME}.${SCAN}_scan.dat"
rm -rf $FILENAME

BASE_THRESHOLD=$(/au/measure/get_threshold.sh $CHIP $CHANNEL)

echo " --- starting loops for ${SCAN} scan " 
echo "     BIAS_VOLTAGES: ${BIAS_VOLTAGES} "
echo "     THRESHOLDS: ${THRESHOLDS} "
echo " --- "
echo "     BASE_THRESHOLD: ${BASE_THRESHOLD} "
echo "     THRESHOLD_SETTINGS: ${THRESHOLD_SETTINGS} "
echo "     REPEAT: ${REPEAT} "
echo "     INTEGRATED: ${INTEGRATED} "
echo " --- "

### switch on HV
/au/masterlogic/zero $CHIP
/au/tti/hv.on
sleep 1

### loop over Vbias values
for BIAS_VOLTAGE in $BIAS_VOLTAGES; do
    
    ### set Vbias
    BIAS_DAC=$(/au/masterlogic/hvcalib/hvcalib-malaguti-${CARRIER}.sh $BIAS_VOLTAGE | grep dac | awk '{print $2}')
    if [ -z "$AU_DRYRUN" ]; then

	### R+HACK
#	/au/masterlogic/set $CHIP $BIAS_DAC
#	/au/masterlogic/set_dac12 $CHIP $DAC12 0
#	/au/masterlogic/wait
	
	/au/masterlogic/set_dac12 $CHIP $DAC12 $BIAS_DAC
	/au/masterlogic/wait

    fi
    
    ### loop over thresholds
    for THRESHOLD in $THRESHOLDS; do
	
	###
	### rate
	###
	
	if [ -z "$AU_DRYRUN" ]; then
	    for i in $(seq 1 $REPEAT); do
		OUTPUT=$(/au/measure/rate.sh $CHIP $CHANNEL $THRESHOLD_SETTINGS $THRESHOLD --min_timer $MIN_TIMER)
		[ -z "$OUTPUT" ] && continue
		echo "bias_voltage = ${BIAS_VOLTAGE} bias_dac = ${BIAS_DAC} ${OUTPUT}" | tee -a $FILENAME
	    done
	fi
	
    done
    ### end of loop over thresholds
done    
### end of loop over Vbias values

### create tree from rate measurements
if [ -z "$AU_DRYRUN" ]; then
    /au/measure/tree.sh $FILENAME bias_voltage/F bias_dac/I \
			threshold/I timestamp/I counts/I period/F rate/F ratee/F temperature/F 
fi

exit

### send tree via email
attachments="${FILENAME}.tree.root"
recipients="roberto.preghenella@bo.infn.it nicola.rubini@bo.infn.it"
mail -r eicdesk01@bo.infn.it \
     -s "[${SCAN} scan] $(basename "`pwd`")" \
     $(for i in $recipients; do echo "$i,"; done) \
     $(for i in $attachments; do echo "-A $i"; done) <<EOF
Working from $PWD.
Completed ${SCAN} scan.

(Do not reply, we won't read it)
EOF
