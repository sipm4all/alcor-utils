#! /usr/bin/env bash

### input parameters
if [ "$#" -ne 5 ]; then
    echo "usage: $0 [scan] [device] [chip] [channel] [masterlogic]"
    exit 1
fi
SCAN="$1"
DEVICE="$2"
CHIP="$3"
CHANNEL="$4"
MASTERLOGIC="$5"
### R+TEMP ### EOCHANNEL=$(/au/readout/python/mapping.py --xy2eo $CHANNEL)
EOCHANNEL=$CHANNEL ### R+TEMP ###
BASE_THRESHOLD=$(/au/pdu/measure/get_threshold.sh $DEVICE $CHIP $CHANNEL)

echo " --- "
echo " --- running ureadout DCR $SCAN scan: device $DEVICE chip $CHIP channel $CHANNEL masterlogic $MASTERLOGIC "
echo " --- "

### op mode
if [ -z "$AU_OPMODE" ]; then
    echo " --- AU_OPMODE undefined "
    exit 1
fi
OPMODE=${AU_OPMODE}

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
DELTA_THRESHOLDS=$(seq 1 $AU_SCAN_THRESHOLD_STEP 25 | tr "\n" " ") ### R+HACK

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
INTEGRATED=0.01 ### R+HACK

### delete raw data
DELETE_RAW_DATA=true
if [ -z "$AU_DELETE_RAW_DATA" ]; then
    echo " --- AU_DELETE_RAW_DATA undefined "
    exit 1
fi
DELETE_RAW_DATA=${AU_DELETE_RAW_DATA}

### delete decoded data
if [ -z "$AU_DELETE_DECODED_DATA" ]; then
    echo " --- AU_DELETE_DECODED_DATA undefined "
    exit 1
fi
DELETE_DECODED_DATA=${AU_DELETE_DECODED_DATA}

### run analysis
if [ -z "$AU_RUN_ANALYSIS" ]; then
    echo " --- AU_RUN_ANALYSIS undefined "
    exit 1
fi
RUN_ANALYSIS=${AU_RUN_ANALYSIS}

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

### alcor fast init
#/au/pdu/control/alcor_fast_init_readout.sh ${DEVICE} ${CHIP} ${EOCHANNEL}

### ready to start
DIRNAME="rate/${SCAN}_scan/chip${CHIP}-${CHANNEL}"
mkdir -p ${DIRNAME}
cd $DIRNAME

echo " --- starting loops for ${SCAN} scan " 
echo "     BIAS_VOLTAGES: ${BIAS_VOLTAGES} "
echo "     DELTA_THRESHOLDS: ${DELTA_THRESHOLDS} "
echo " --- "
echo "     BASE_THRESHOLD: ${BASE_THRESHOLD} "
echo "     THRESHOLD_SETTINGS: ${THRESHOLD_SETTINGS} "
echo "     REPEAT: ${REPEAT} "
echo "     INTEGRATED: ${INTEGRATED} "
echo "     OPMODE: ${OPMODE} "
echo "     DELETE RAW/DECODED DATA: ${DELETE_RAW_DATA}/${DELETE_DECODED_DATA} "
echo " --- "

### switch on HV
if [ -z "$AU_BIAS_MANUAL" ]; then
    /au/pdu/masterlogic/zero $MASTERLOGIC
fi
#/au/tti/hv.on
sleep 1

### loop over Vbias values
for BIAS_VOLTAGE in $BIAS_VOLTAGES; do
    
    ### set Vbias
    if [ -z "$AU_DRYRUN" ]; then
	if [ -z "$AU_BIAS_MANUAL" ]; then
	    /au/pdu/masterlogic/vbias $MASTERLOGIC "all" $BIAS_VOLTAGE
	fi
	/au/pdu/masterlogic/wait.sh
    fi
    
    ### loop over thresholds
    for DELTA_THRESHOLD in $DELTA_THRESHOLDS; do
	
	THRESHOLD=$((BASE_THRESHOLD + DELTA_THRESHOLD))
	if [ "$THRESHOLD" -gt 63 ] || [ "$THRESHOLD" -lt 0 ]; then
	    continue
	fi

	###
	### ureadout
	###
	
	if [ -z "$AU_DRYRUN" ]; then
	    for i in $(seq 1 $REPEAT); do

#		OUTPUT_PREFIX="ureadout_bias_voltage=${BIAS_VOLTAGE}_biasdac=${BIAS_DAC}_basethreshold=${BASE_THRESHOLD}_threshold=${THRESHOLD}"
		OUTPUT_PREFIX="ureadout_bias_voltage=${BIAS_VOLTAGE}_basethreshold=${BASE_THRESHOLD}_threshold=${THRESHOLD}"
		OUTPUT_TAGNAME="${OUTPUT_PREFIX}.chip_${CHIP}.channel_${EOCHANNEL}"

		### collect data
		echo " --- ureadout: $OUTPUT_TAGNAME "
		/au/readout/bin/ureadout --connection /etc/drich/drich_ipbus_connections.xml \
					 --device ${DEVICE} \
					 --output $OUTPUT_PREFIX \
					 --chip $CHIP \
					 --channel $EOCHANNEL \
					 --max_resets 10 \
					 --timer 312500 \
					 --integrated $INTEGRATED \
					 --opmode $OPMODE \
					 --noinit \
					 --threshold $THRESHOLD >> ureadout.log
		
		### not too many at the same time
#		while [ $(pgrep -c -f /au/readout/bin/decoder) -gt 16 ]; do sleep 1; done
		while [ $(pgrep -c -f root.exe) -gt 2 ]; do sleep 1; done

		### decode, analyse and finalise
		echo " --- decode and analyse: $OUTPUT_TAGNAME "
		/au/readout/bin/decoder --input $OUTPUT_TAGNAME.alcor.dat --output $OUTPUT_PREFIX.root >> decoder.log && \
    		    if [ $DELETE_RAW_DATA = true ]; then rm $OUTPUT_TAGNAME.*.dat; fi && \
		    if [ $RUN_ANALYSIS = true ]; then root -b -q -l "${ALCOR_DIR}/measure/2023-characterisation/ureadout_dcr_analysis.C(\"${OUTPUT_PREFIX}.root\", \"dcr_${OUTPUT_PREFIX}.root\")" >> ureadout_dcr_analysis.log >> decoder.log; fi && \
		    if [ $DELETE_DECODED_DATA = true ]; then rm $OUTPUT_PREFIX.root; fi &
		
		# echo "bias_voltage = ${BIAS_VOLTAGE} bias_dac = ${BIAS_DAC} base_threshold = ${BASE_THRESHOLD} ${OUTPUT}" | tee -a $FILENAME

		
	    done
	fi
	
    done
    ### end of loop over thresholds
done    
### end of loop over Vbias values

wait
#rm -f *.log
cd ..


### switch off HV
if [ -z "$AU_BIAS_MANUAL" ]; then
    /au/pdu/masterlogic/zero.sh $MASTERLOGIC
fi
#/au/tti/hv.off
sleep 1

### create tree from measurements
if [ -z "$AU_DRYRUN" ]; then
    if [ $RUN_ANALYSIS = true ]; then
	root -b -q -l "${ALCOR_DIR}/measure/2023-characterisation/ureadout_dcr_create_tree.C(\"chip${CHIP}-${CHANNEL}\", \"chip${CHIP}-${CHANNEL}.ureadout_dcr_scan.tree.root\")"
    fi
fi

exit

