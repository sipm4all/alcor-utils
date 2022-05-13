#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [chip] [channel]"
    exit 1
fi
CHIP=$1
CHANNEL="$2"
EOCHANNEL=$(/au/readout/python/mapping.py --xy2eo $CHANNEL)

TAGNAME="chip${CHIP}-${CHANNEL}"
FILENAME="${TAGNAME}.threshold_scan.dat"
rm -rf $FILENAME

### pulse voltages [mV]
[ -z "$AU_PULSE_VOLTAGES" ] && PULSE_VOLTAGES="960 980 1000" || PULSE_VOLTAGES=${AU_PULSE_VOLTAGES}

### sipm bias reference voltages [V]
[ -z "$AU_BIAS_REF_VOLTAGES" ] && BIAS_REF_VOLTAGES="54 55 56" || BIAS_REF_VOLTAGES=${AU_BIAS_REF_VOLTAGES}
TEMPERATURE="-30"

### delta thresholds
[ -z "$AU_DELTA_THRESHOLDS" ] && DELTA_THRESHOLDS="3 5" || DELTA_THRESHOLDS=${AU_DELTA_THRESHOLDS}

### frequencies [kHz]
[ -z "$AU_SCAN_PULSE_FREQUENCIES" ] && PULSE_FREQUENCIES="10 100" || PULSE_FREQUENCIES=${AU_SCAN_PULSE_FREQUENCIES}

### repetitions
[ -z "$AU_SCAN_REPEAT" ]  && REPEAT=100  || REPEAT=${AU_SCAN_REPEAT}
[ -z "$AU_SCAN_UREPEAT" ] && UREPEAT=100 || UREPEAT=${AU_SCAN_UREPEAT}

### [TODO] recompute repetitions based on frequency


### loop over Fpulse values
for PULSE_FREQUENCY in $PULSE_FREQUENCIES; do
    
    ### loop over Vpulse values
    for PULSE_VOLTAGE in $PULSE_VOLTAGES; do
	
	/au/pulser/set --voltage $PULSE_VOLTAGE --frequency $PULSE_FREQUENCY
	
	### loop over Vbias values
	for BIAS_REF_VOLTAGE in $BIAS_REF_VOLTAGES; do
	    
	    ### set Vbias
	    BIAS_VOLTAGE=$(/au/hvsetup/hv-calib/hvcalib-bo-hama1.sh $TEMPERATURE $BIAS_REF_VOLTAGE | grep vbias | awk '{print $2}')
	    BIAS_DAC=$(/au/hvsetup/hv-calib/hvcalib-bo-hama1.sh $TEMPERATURE $BIAS_REF_VOLTAGE | grep dac | awk '{print $2}')
	    /au/masterlogic/set $CHIP $BIAS_DAC
	    /au/masterlogic/wait
	    
	    ### loop over thresholds
	    for THRESHOLD in $THRESHOLDS; do
		
		### measure rate
		for i in $(seq 1 $REPEAT); do
		    OUTPUT=$(/au/measure/pulser_rate.sh $CHIP $CHANNEL --threshold $THRESHOLD)
		    [ -z "$OUTPUT" ] && continue
		    echo "bias_voltage = ${BIAS_VOLTAGE} bias_dac = ${BIAS_DAC} pulse_voltage = ${PULSE_VOLTAGE} pulse_frequency = ${PULSE_FREQUENCY} ${OUTPUT}" | tee -a $FILENAME
		done
		
		### run ureadout
		#	UDIRNAME="ureadout/vbias_scan/chip$CHIP/$CHANNEL/${PULSE_VOLTAGE}mV/${BIAS_DAC}dac"
		#	UTAGNAME="ureadout.vbias_scan.chip$CHIP.$CHANNEL.${PULSE_VOLTAGE}mV.${BIAS_DAC}dac"
		#	mkdir -p ${UDIRNAME}
		#	rm -rf $UDIRNAME/process.list
		#	for i in $(seq 1 $UREPEAT); do
		#	    UFILENAME="repeat_$i"
		#	    /au/pulser/on
		#	    /au/measure/ureadout.sh $CHIP $CHANNEL $UDIRNAME/$UFILENAME
		#	    echo "$UTAGNAME $UFILENAME $CHIP $EOCHANNEL" >> $UDIRNAME/process.list
		#	done
		
	    done
	done    
    done
done

/au/measure/tree.sh $FILENAME bias_voltage/F bias_dac/I pulse_voltage/I pulse_frequency/I \
		    threshold_off/I timestamp_off/I counts_off/I period_off/F rate_off/F ratee_off/F temperature_off/F \
		    threshold_on/I  timestamp_on/I  counts_on/I  period_on/F  rate_on/F  ratee_on/F  temperature_on/F
