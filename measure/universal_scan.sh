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

### temperature
if [ -z "$AU_TEMPERATURE" ]; then
    echo " --- AU_TEMPERATURE undefined "
    exit 1
fi
TEMPERATURE=${AU_TEMPERATURE}

### pulse voltages [mV]
if [ -z "$AU_PULSE_VOLTAGES" ]; then
   echo " --- AU_PULSE_VOLTAGES undefined "
   exit 1
fi
PULSE_VOLTAGES=${AU_PULSE_VOLTAGES}

### sipm bias reference voltages [V]
if [ -z "$AU_BIAS_REF_VOLTAGES" ]; then
    echo " --- AU_BIAS_REF_VOLTAGES undefiend "
    exit 1
fi
BIAS_REF_VOLTAGES=${AU_BIAS_REF_VOLTAGES}

### delta thresholds
if [ -z "$AU_DELTA_THRESHOLDS" ]; then
    echo " --- AU_DELTA_THRESHOLDS undefined "
    exit 1
fi
DELTA_THRESHOLDS=${AU_DELTA_THRESHOLDS}

### frequencies [kHz]
if [ -z "$AU_PULSE_FREQUENCIES" ]; then
    echo " --- AU_PULSE_FREQUENCIES undefined "
    exit 1
fi
PULSE_FREQUENCIES=${AU_PULSE_FREQUENCIES}

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

### ureadout repetitions
if [ -z "$AU_UREPEAT" ]; then
    echo " --- AU_UREPEAT undefined "
    exit 1
fi
UREPEAT=${AU_UREPEAT}

### ureadout integrated
if [ -z "$AU_UINTEGRATED" ]; then
    echo " --- AU_UINTEGRATED undefined "
    exit 1
fi
UINTEGRATED=${AU_UINTEGRATED}

### check if this is a test scan
if [[ "${SCAN}" == "test"* ]]; then

    echo " --- this is a TEST "
    
    ### pulse voltages [mV]
    if [ -z "$AU_TEST_PULSE_VOLTAGES" ]; then
	echo " --- AU_TEST_PULSE_VOLTAGES undefined "
	exit 1
    fi
    PULSE_VOLTAGES=${AU_TEST_PULSE_VOLTAGES}
    
    ### sipm bias reference voltages [V]
    if [ -z "$AU_TEST_BIAS_REF_VOLTAGES" ]; then
	echo " --- AU_TEST_BIAS_REF_VOLTAGES undefiend "
	exit 1
    fi
    BIAS_REF_VOLTAGES=${AU_TEST_BIAS_REF_VOLTAGES}
    
    ### delta thresholds
    if [ -z "$AU_TEST_DELTA_THRESHOLDS" ]; then
	echo " --- AU_TEST_DELTA_THRESHOLDS undefined "
	exit 1
    fi
    DELTA_THRESHOLDS=${AU_TEST_DELTA_THRESHOLDS}
    
    ### frequencies [kHz]
    if [ -z "$AU_TEST_PULSE_FREQUENCIES" ]; then
	echo " --- AU_TEST_PULSE_FREQUENCIES undefined "
	exit 1
    fi
    PULSE_FREQUENCIES=${AU_TEST_PULSE_FREQUENCIES}
    
fi

### change variables depending on scan type
case $SCAN in
    *vbias)
	if [ -z "$AU_SCAN_BIAS_REF_VOLTAGES" ]; then
	    echo " --- AU_SCAN_BIAS_REF_VOLTAGES undefined "
	    exit 1
	fi
	BIAS_REF_VOLTAGES=${AU_SCAN_BIAS_REF_VOLTAGES}
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
    *frequency)
	if [ -z "$AU_SCAN_PULSE_FREQUENCIES" ]; then
	    echo " --- AU_SCAN_PULSE_FREQUENCIES undefined "
	    exit 1
	fi
	PULSE_FREQUENCIES=${AU_SCAN_PULSE_FREQUENCIES}
	THRESHOLDS=${DELTA_THRESHOLDS}
	THRESHOLD_SETTINGS="--delta_threshold"
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
echo "     PULSE_FREQUENCIES: ${PULSE_FREQUENCIES} "
echo "     PULSE_VOLTAGES: ${PULSE_VOLTAGES} "
echo "     BIAS_REF_VOLTAGES: ${BIAS_REF_VOLTAGES} "
echo "     THRESHOLDS: ${THRESHOLDS} "
echo " --- "
echo "     BASE_THRESHOLD: ${BASE_THRESHOLD} "
echo "     THRESHOLD_SETTINGS: ${THRESHOLD_SETTINGS} "
echo "     REPEAT: ${REPEAT} "
echo "     INTEGRATED: ${INTEGRATED} "
echo "     UREPEAT: ${UREPEAT} "
echo "     UINTEGRATED: ${UINTEGRATED} "
echo " --- "

### switch on HV
/au/masterlogic/zero $CHIP
/au/tti/hv.on
sleep 1

### loop over Fpulse values
for PULSE_FREQUENCY in $PULSE_FREQUENCIES; do
    
    ### compute repetitions based on frequency scaling
    REPEAT=$(bc -l <<< "scale=0; ( ${AU_REPEAT} * 100 / ${PULSE_FREQUENCY} ) / 1")
    UREPEAT=$(bc -l <<< "scale=0; ( ${AU_UREPEAT} * 100 / ${PULSE_FREQUENCY} ) / 1")
    
    ### loop over Vpulse values
    for PULSE_VOLTAGE in $PULSE_VOLTAGES; do

	### set pulser
	if [ -z "$AU_DRYRUN" ]; then
	    /au/pulser/set --voltage $PULSE_VOLTAGE --frequency $PULSE_FREQUENCY
	fi
	
	### loop over Vbias values
	for BIAS_REF_VOLTAGE in $BIAS_REF_VOLTAGES; do
	    
	    ### set Vbias
	    BIAS_VOLTAGE=$(/au/hvsetup/hv-calib/hvcalib-bo-hama1.sh $TEMPERATURE $BIAS_REF_VOLTAGE | grep vbias | awk '{print $2}')
	    BIAS_DAC=$(/au/hvsetup/hv-calib/hvcalib-bo-hama1.sh $TEMPERATURE $BIAS_REF_VOLTAGE | grep dac | awk '{print $2}')
	    if [ -z "$AU_DRYRUN" ]; then
#		/au/masterlogic/set $CHIP $BIAS_DAC
#		/au/masterlogic/wait
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
			OUTPUT=$(/au/measure/pulser_rate.sh $CHIP $CHANNEL $THRESHOLD_SETTINGS $THRESHOLD --integrated $INTEGRATED)
			[ -z "$OUTPUT" ] && continue
			echo "bias_voltage = ${BIAS_VOLTAGE} bias_dac = ${BIAS_DAC} pulse_voltage = ${PULSE_VOLTAGE} pulse_frequency = ${PULSE_FREQUENCY} base_threshold = ${BASE_THRESHOLD} ${OUTPUT}" | tee -a $FILENAME
		    done
		fi

		###
		### ureadout
		###

		### avoid doing if threshold is below base value
		if [ "${THRESHOLD_SETTINGS}" = "--threshold" ] && [ "$THRESHOLD" -le "$BASE_THRESHOLD" ]; then
		    echo " --- not doing ureadout: $THRESHOLD <= $BASE_THRESHOLD "
		    continue;
		fi
		
		### directory structure depending on scan type
		case $SCAN in
		    *vbias)
			UTAGNAME="pulse_frequency_${PULSE_FREQUENCY} pulse_voltage_${PULSE_VOLTAGE} ${THRESHOLD_SETTINGS:2}_${THRESHOLD} bias_dac_${BIAS_DAC}"
			;;
		    *threshold)
			UTAGNAME="pulse_frequency_${PULSE_FREQUENCY} pulse_voltage_${PULSE_VOLTAGE} bias_dac_${BIAS_DAC} ${THRESHOLD_SETTINGS:2}_${THRESHOLD}"
			;;
		    *frequency)
			UTAGNAME="pulse_voltage_${PULSE_VOLTAGE} ${THRESHOLD_SETTINGS:2}_${THRESHOLD} bias_dac_${BIAS_DAC} pulse_frequency_${PULSE_FREQUENCY}"
			;;
		esac
#		UTAGNAME="pulse_frequency_${PULSE_FREQUENCY}.pulse_voltage_${PULSE_VOLTAGE}.bias_dac_${BIAS_DAC}.${THRESHOLD_SETTINGS:2}_${THRESHOLD}"
#		UDIRNAME="ureadout/${SCAN}_scan/${UTAGNAME}"
		
		UDIRNAME="ureadout/${SCAN}_scan/$(echo ${UTAGNAME} | tr " " "/")"
		mkdir -p ${UDIRNAME}
		if [ -z "$AU_DRYRUN" ]; then
		    /au/pulser/on
		    for i in $(seq 1 $UREPEAT); do
			UFILENAME="ureadout.repeat_$i"
			echo $CHIP $CHANNEL $UDIRNAME/$UFILENAME >> "ureadout/${SCAN}_scan/process.list"
			/au/measure/ureadout.sh $CHIP $CHANNEL $UDIRNAME/$UFILENAME $THRESHOLD_SETTINGS $THRESHOLD --integrated $UINTEGRATED
		    done
		fi
		
	    done
	    ### end of loop over thresholds
	done    
	### end of loop over Vbias values
    done
    ### end of loop over Vpulse values
done
### end of loop over Fpulse values

### switch off HV
/au/masterlogic/zero $CHIP
/au/tti/hv.off
sleep 1

### create tree from pulse rate measurements
if [ -z "$AU_DRYRUN" ]; then
    /au/measure/tree.sh $FILENAME bias_voltage/F bias_dac/I pulse_voltage/I pulse_frequency/I base_threshold/I \
			threshold_off/I timestamp_off/I counts_off/I period_off/F rate_off/F ratee_off/F temperature_off/F \
			threshold_on/I  timestamp_on/I  counts_on/I  period_on/F  rate_on/F  ratee_on/F  temperature_on/F
fi

### send tree via email
attachments="${FILENAME}.tree.root"
#recipients="roberto.preghenella@bo.infn.it nicola.rubini@bo.infn.it"
recipients="roberto.preghenella@bo.infn.it"
mail -r eicdesk01@bo.infn.it \
     -s "[${SCAN} scan] $(basename "`pwd`")" \
     $(for i in $recipients; do echo "$i,"; done) \
     $(for i in $attachments; do echo "-A $i"; done) <<EOF
Working from $PWD.
Completed ${SCAN} scan.

(Do not reply, we won't read it)
EOF
