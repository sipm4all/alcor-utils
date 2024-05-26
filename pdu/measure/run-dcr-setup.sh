#! /usr/bin/env bash

### default parameters
BCRCONF=standard

### external parameters
if [ "$#" -ne 3 ]; then
    echo " usage: $0 [run-name] [device] [setup] "
    echo " available setups: "
    echo "    pdu-scan-setup "
    echo "    pdu-test-setup "
    echo "    system-noise-scan "
    exit 1
fi
runname=$1
DEVICE=$2
SETUP=$3

### standard measurement settings
export AU_BIAS_VOLTAGES="35 37"  # [V]
export AU_DELTA_THRESHOLDS="5"
export AU_INTEGRATED="1.0"
export AU_REPEAT=1

### scan settings
export AU_OPMODE=1
export AU_DELETE_RAW_DATA=true
export AU_RUN_ANALYSIS=true
export AU_DELETE_DECODED_DATA=true
export AU_SCAN_BIAS_STEP="0.5"
export AU_SCAN_BIAS_VOLTAGES=$(seq 30 $AU_SCAN_BIAS_STEP 38 | tr "\n" " ") # [V]
export AU_SCAN_THRESHOLD_STEP="2"
export AU_SCAN_DELTA_THRESHOLDS=$(seq 1 $AU_SCAN_THRESHOLD_STEP 63 | tr "\n" " ")

### scans to be performed
export AU_SCANS="vbias threshold"
export AU_CHANNELS=$(seq 0 31)

### uncomment to dry run
# export AU_DRYRUN=true

###
### S13 scan values
###
S13_BIAS_VOLTAGES="51"
S13_SCAN_BIAS_VOLTAGES=$(seq 48 $AU_SCAN_BIAS_STEP 58 | tr "\n" " ")

###
### S14 scan values
###
S14_BIAS_VOLTAGES="39"
S14_SCAN_BIAS_VOLTAGES=$(seq 36 $AU_SCAN_BIAS_STEP 43 | tr "\n" " ")

main()
{

    ### prepare directory
    BASEDIR=$HOME/DATA/2024-testbeam/actual/dcr-scan/${DEVICE}
    DIR=$BASEDIR/${runname}
    mkdir -p $DIR
    ln -sfn $DIR $BASEDIR/latest
    cd $DIR

    echo " --- running ${SETUP} DCR setup on device ${DEVICE}: $PWD "
    echo " --- "
    echo "$(date +%s) | $(date) "
    echo " --- "
    
    ### notify database
    telegram_message.sh "started DCR scan: ${DEVICE}"
    influx_write.sh "kc705,device=${DEVICE},name=dcr-scan value=1"

    ### make sure firmware is fresh
    echo " --- programming FPGA: /home/eic/bin/drich_kc705_program.sh ${device} "
    echo " --- "
    echo "$(date +%s) | $(date) "
    echo " --- "
    /home/eic/bin/drich_kc705_program.sh ${DEVICE} &> program.log
    sleep 3

    ### run baseline calibration
#    echo " --- running baseline calibration: /au/pdu/measure/run-baseline-calibration.sh ${DEVICE} "
#    echo " --- "
#    echo "$(date +%s) | $(date) "
#    echo " --- "
#    /au/pdu/measure/run-baseline-calibration.sh ${DEVICE} &> run-baseline-calibration.${DEVICE}.log

    ### link baseline readout.conf
    ln -sf /au/pdu/conf/readout.${DEVICE}.baseline.conf /au/pdu/conf/readout.${DEVICE}.conf
    
    ### ALCOR init
    echo " --- ALCOR init: /au/pdu/control/alcorInit.sh ${DEVICE} 666 /tmp"
    echo " --- "
    echo "$(date +%s) | $(date) "
    echo " --- "
    /au/pdu/control/alcorInit.sh ${DEVICE} 0 /tmp &> alcorInit.log
    sleep 3

    echo " --- really running ${SETUP} DCR setup "
    echo " --- "
    echo "$(date +%s) | $(date) "
    echo " --- "
    $SETUP $DEVICE &> run-dcr-setup.log
    
    ### link back run readout.conf
    ln -sf /au/pdu/conf/readout.${DEVICE}.current.conf /au/pdu/conf/readout.${DEVICE}.conf

    ### notify database 
    telegram_message.sh "DCR scan completed: ${DEVICE}"
    influx_write.sh "kc705,device=${DEVICE},name=dcr-scan value=0"

    cd - &> /dev/null

    echo " --- DONE "
    echo " --- "
    echo "$(date +%s) | $(date) "
    echo " --- "    

}

pdu-test-setup()
{
    export AU_BIAS_MANUAL="true"
    export AU_INTEGRATED="0.01"
    export AU_SCANS="threshold"
    export AU_CHANNELS=$(seq 0 8 31)
    export AU_SCAN_DELTA_THRESHOLDS=$(seq 1 $AU_SCAN_THRESHOLD_STEP 35 | tr "\n" " ")
   
    export S13_BIAS_VOLTAGES="54"
    export S13_SCAN_BIAS_VOLTAGES=$(seq 52 $AU_SCAN_BIAS_STEP 58 | tr "\n" " ")
    export S14_BIAS_VOLTAGES="42"
    export S14_SCAN_BIAS_VOLTAGES=$(seq 39 $AU_SCAN_BIAS_STEP 43 | tr "\n" " ")

    run-dcr-setup $1
}

pdu-scan-setup()
{
    export AU_BIAS_MANUAL="true"
    export AU_INTEGRATED="0.01"
    export AU_SCANS="threshold"
    export AU_CHANNELS=$(seq 0 31)
    export AU_CHANNELS=$(seq 0 8 31)
    export AU_SCAN_DELTA_THRESHOLDS=$(seq 1 $AU_SCAN_THRESHOLD_STEP 35 | tr "\n" " ")
   
    export S13_BIAS_VOLTAGES="54"
    export S13_SCAN_BIAS_VOLTAGES=$(seq 52 $AU_SCAN_BIAS_STEP 58 | tr "\n" " ")
    export S14_BIAS_VOLTAGES="42"
    export S14_SCAN_BIAS_VOLTAGES=$(seq 39 $AU_SCAN_BIAS_STEP 43 | tr "\n" " ")

    run-dcr-setup $1
}

system-noise-scan()
{
    export AU_SCAN_THRESHOLD_STEP="1"
    export AU_SCAN_DELTA_THRESHOLDS=$(seq -63 $AU_SCAN_THRESHOLD_STEP 63 | tr "\n" " ")
    
    export AU_BIAS_MANUAL="true"
    export AU_INTEGRATED="0.1"
    export AU_SCANS="threshold"
    export AU_CHANNELS=$(seq 0 31)
#    export AU_CHANNELS=$(seq 0 8 31)
#    export AU_CHANNELS=0
    
    export S13_BIAS_VOLTAGES="54"
    export S13_SCAN_BIAS_VOLTAGES=$(seq 52 $AU_SCAN_BIAS_STEP 58 | tr "\n" " ")
    export S14_BIAS_VOLTAGES="42"
    export S14_SCAN_BIAS_VOLTAGES=$(seq 39 $AU_SCAN_BIAS_STEP 43 | tr "\n" " ")

    run-dcr-setup $1
}

run-dcr-setup()
{
    device=$1
    chips=$(awk -v device="$device" '$1 !~ /^#/ && $4 == device' /etc/drich/drich_readout.conf | awk {'print $5, $6'} | tr '\n' ' ')
    for chip in $chips; do
	[[ ! $chip =~ ^[0-5]$ ]] && continue
	type=$(awk -v device="$device" -v chip=$chip '$1 !~ /^#/ && $4 == device && ($5 == chip || $6 == chip)' /etc/drich/drich_readout.conf | awk {'print $2'} | tr '\n' ' ')
	masterlogic=$(awk -v device="$device" -v chip=$chip '$1 !~ /^#/ && $4 == device && ($5 == chip || $6 == chip)' /etc/drich/drich_readout.conf | awk {'print $7'} | tr '\n' ' ')
	run-dcr-scan $device $chip $masterlogic $type
    done
}

run-dcr-scan()
{
    device=$1
    chip=$2
    masterlogic=$3
    type=$4

    echo " --- "
    echo " --- running DCR scan: device $device | chip $chip | masterlogic $masterlogic | sensor type $type"
    echo " --- "

    if [[ $type == "s13" ]]; then
	export AU_BIAS_VOLTAGES=$S13_BIAS_VOLTAGES
	export AU_SCAN_BIAS_VOLTAGES=$S13_SCAN_BIAS_VOLTAGES
    elif [[ $type == "s14" ]]; then
	export AU_BIAS_VOLTAGES=$S14_BIAS_VOLTAGES
	export AU_SCAN_BIAS_VOLTAGES=$S14_SCAN_BIAS_VOLTAGES
    else
	echo " --- ERROR: unknown sensor type: $type "
	return
    fi

    mkdir -p $type-chip${chip}
    cd $type-chip${chip}

    scan_chip $device $chip $masterlogic
    /au/pdu/measure/draw_dcr_scan.sh $chip 50 60
    
    cd ..

}

scan_chip()
{    
    device=$1
    chip=$2
    masterlogic=$3
    for channel in $AU_CHANNELS; do
	for scan in $AU_SCANS; do
	    time -p /au/pdu/measure/ureadout-dcr-scan.sh $scan $device $chip $channel $masterlogic
	done
    done
}

main $1

