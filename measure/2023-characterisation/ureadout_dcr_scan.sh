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
BASE_THRESHOLD=$(/au/measure/get_threshold.sh $CHIP $CHANNEL)
DAC12=$(echo "scale=0; $DOCHANNEL / 4" | bc -l)

echo " --- "
echo " --- running ureadout DCR $SCAN scan: chip $CHIP channel $CHANNEL "
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

### change variables depending on scan type
case $SCAN in
    *vbias)
	if [ -z "$AU_SCAN_BIAS_VOLTAGES" ]; then
	    echo " --- AU_SCAN_BIAS_VOLTAGES undefined "
	    exit 1
	fi
	BIAS_VOLTAGES=${AU_SCAN_BIAS_VOLTAGES}
	DELTA_THRESHOLDS=${DELTA_THRESHOLDS}
	THRESHOLD_SETTINGS="--delta_threshold"
	;;
    *threshold)
	if [ -z "$AU_SCAN_DELTA_THRESHOLDS" ]; then
	    echo " --- AU_SCAN_DELTA_THRESHOLDS undefined "
	    exit 1
	fi
	DELTA_THRESHOLDS=${AU_SCAN_DELTA_THRESHOLDS}
	THRESHOLD_SETTINGS="--delta_threshold"
	;;
    *)
	echo " --- unknown scan type: ${SCAN} "
	exit 1
esac

### ready to start
DIRNAME="rate/${SCAN}_scan/chip${CHIP}-${CHANNEL}"
mkdir -p ${DIRNAME}
cd $DIRNAME

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
if [ -z "$AU_BIAS_MANUAL" ]; then
    /au/masterlogic/zero $CHIP
fi
/au/tti/hv.on
sleep 1

### loop over Vbias values
for BIAS_VOLTAGE in $BIAS_VOLTAGES; do
    
    ### set Vbias
    BIAS_DAC=$(/au/masterlogic/hvcalib/hvcalib-malaguti-${CARRIER}.sh $BIAS_VOLTAGE | grep dac | awk '{print $2}')
    if [ -z "$AU_DRYRUN" ]; then

	if [ -z "$AU_BIAS_MANUAL" ]; then
	    /au/masterlogic/set_dac12 $CHIP $DAC12 $BIAS_DAC
	fi
	/au/masterlogic/wait

    fi
    
    ### loop over thresholds
    for DELTA_THRESHOLD in $DELTA_THRESHOLDS; do
	
	THRESHOLD=$((BASE_THRESHOLD + DELTA_THRESHOLD))
	
	if [ "$THRESHOLD" -gt 63 ]; then
	    continue
	fi

	###
	### ureadout
	###
	
	if [ -z "$AU_DRYRUN" ]; then
	    for i in $(seq 1 $REPEAT); do

		OUTPUT_PREFIX="ureadout_bias_voltage=${BIAS_VOLTAGE}_biasdac=${BIAS_DAC}_basethreshold=${BASE_THRESHOLD}_threshold=${THRESHOLD}"
		OUTPUT_TAGNAME="${OUTPUT_PREFIX}.chip_${CHIP}.channel_${EOCHANNEL}"

		### collect data
		echo " --- ureadout: $OUTPUT_TAGNAME "
		/au/readout/bin/ureadout --connection /au/etc/connection2.xml \
					 --output $OUTPUT_PREFIX \
					 --chip $CHIP \
					 --channel $EOCHANNEL \
					 --max_resets 10 \
					 --timer 320000 \
					 --integrated $INTEGRATED \
					 --opmode 1 \
					 --threshold $THRESHOLD >> ureadout.log
		
		### decode, analyse and finalise
		/au/readout/bin/decoder --input $OUTPUT_TAGNAME.alcor.dat --output $OUTPUT_PREFIX.root >> decoder.log && \
    		    if true; then rm $OUTPUT_TAGNAME.*.dat; fi && \
		    root -b -q -l "${ALCOR_DIR}/measure/2023-characterisation/ureadout_dcr_analysis.C(\"${OUTPUT_PREFIX}.root\", \"dcr_${OUTPUT_PREFIX}.root\")" >> ureadout_dcr_analysis.log && \
		    if true; then rm $OUTPUT_PREFIX.root; fi &
		
		# echo "bias_voltage = ${BIAS_VOLTAGE} bias_dac = ${BIAS_DAC} base_threshold = ${BASE_THRESHOLD} ${OUTPUT}" | tee -a $FILENAME

		
	    done
	fi
	
    done
    ### end of loop over thresholds
done    
### end of loop over Vbias values

wait
cd ..

### switch off HV
if [ -z "$AU_BIAS_MANUAL" ]; then
    /au/masterlogic/zero $CHIP
fi
#/au/tti/hv.off
sleep 1

### create tree from measurements
if [ -z "$AU_DRYRUN" ]; then
    root -b -q -l "${ALCOR_DIR}/measure/2023-characterisation/ureadout_dcr_create_tree.C(\"chip${CHIP}-${CHANNEL}\", \"chip${CHIP}-${CHANNEL}.ureadout_dcr_scan.tree.root\")"
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
