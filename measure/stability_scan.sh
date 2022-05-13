#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [chip] [channel]"
    exit 1
fi
CHIP=$1
CHANNEL="$2"
EOCHANNEL=$(/au/readout/python/mapping.py --xy2eo $CHANNEL)

TAGNAME="chip${CHIP}-${CHANNEL}"

### pulse voltages [mV]
PULSE_VOLTAGES="960 980 1000" # [mV]

### sipm bias reference voltages [V]
BIAS_REF_VOLTAGES="54 55 56"
TEMPERATURE="-30"

REPEAT=100
UREPEAT=$REPEAT

for LOOP in $(seq 0 1000); do

    ### program firmware
    /au/firmware/program.sh new 210203A62F62A true
    sleep 10
    
    FILENAME="${TAGNAME}.stability_scan.$(date +%s).dat"
    rm -rf $FILENAME
    
    time -p for PULSE_VOLTAGE in $PULSE_VOLTAGES; do
	
	/au/pulser/set --voltage $PULSE_VOLTAGE
	
	for BIAS_REF_VOLTAGE in $BIAS_REF_VOLTAGES; do
	    
	    BIAS_VOLTAGE=$(/au/hvsetup/hv-calib/hvcalib-bo-hama1.sh $TEMPERATURE $BIAS_REF_VOLTAGE | grep vbias | awk '{print $2}')
	    BIAS_DAC=$(/au/hvsetup/hv-calib/hvcalib-bo-hama1.sh $TEMPERATURE $BIAS_REF_VOLTAGE | grep dac | awk '{print $2}')
	    
	    /au/masterlogic/set $CHIP $BIAS_DAC
	    sleep 0.1
	    
	    ### rate
	    for i in $(seq 1 $REPEAT); do
		### rate
		OUTPUT=$(/au/measure/pulser_rate.sh $CHIP $CHANNEL)
		echo "loop = $LOOP bias_voltage = $BIAS_VOLTAGE bias_dac = $BIAS_DAC pulse_voltage = $PULSE_VOLTAGE $OUTPUT" | tee -a $FILENAME
	    done
	    
	    ### ureadout
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
    
    /au/measure/tree.sh $FILENAME loop/I bias_voltage/F bias_dac/I pulse_voltage/I temperature_on/F temperature_off/F timestamp_on/I timestamp_off/I counts_on/I counts_off/I period_on/F period_off/F rate_on/F rate_off/F
done


