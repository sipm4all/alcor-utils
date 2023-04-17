#! /usr/bin/env bash

### standard measurement settings
export AU_TEMPERATURE="-30"             # [C]
export AU_PULSE_VOLTAGES="960 1000"     # [mV] (was 960 980 1000)
export AU_PULSE_FREQUENCIES="100 1000"  # [kHz]
export AU_BIAS_VOLTAGES="54 56"     # [V @ T = 20C]
export AU_DELTA_THRESHOLDS="3 5"
export AU_INTEGRATED="0.1"              # pulser_rate integration
export AU_REPEAT=25                     # pulse_rate repetitions
export AU_UINTEGRATED="1"               # ureadout integration
export AU_UREPEAT=5                     # ureadout repetitions

### test measurement settings
export AU_TEST_PULSE_VOLTAGES="960"     # [mV]
export AU_TEST_PULSE_FREQUENCIES="100"  # [kHz]
export AU_TEST_BIAS_VOLTAGES="54"   # [V @ T = 20C]
export AU_TEST_DELTA_THRESHOLDS="3"

### scan settings
export AU_SCAN_BIAS_VOLTAGES=$(seq 51 0.5 59 | tr "\n" " ") # [V @ T = 20C]
export AU_SCAN_THRESHOLDS=$(seq 0 3 63 | tr "\n" " ")
export AU_SCAN_PULSE_FREQUENCIES="100 50 10"

###
### FBK scan values
###
FBK_EVEN_BIAS_VOLTAGES="33 35"
FBK_EVEN_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 38 | tr "\n" " ")
FBK_ODD_BIAS_VOLTAGES="35 37"
FBK_ODD_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 40 | tr "\n" " ")

###
### HAMA1 scan values
###
HAMA1_EVEN_BIAS_VOLTAGES="51 53"
HAMA1_EVEN_SCAN_BIAS_VOLTAGES=$(seq 48 0.5 58 | tr "\n" " ")
HAMA1_ODD_BIAS_VOLTAGES="53 55"
HAMA1_ODD_SCAN_BIAS_VOLTAGES=$(seq 48 0.5 60 | tr "\n" " ")

###
### HAMA2 scan values
###
HAMA2_EVEN_BIAS_VOLTAGES="39 41"
HAMA2_EVEN_SCAN_BIAS_VOLTAGES=$(seq 36 0.5 43 | tr "\n" " ")
HAMA2_ODD_BIAS_VOLTAGES="41 43"
HAMA2_ODD_SCAN_BIAS_VOLTAGES=$(seq 36 0.5 45 | tr "\n" " ")

### scans to be performed
export AU_SCANS="vbias"

### uncomment to dry run
# export AU_DRYRUN=true

### we must ensure that we run a baseline calibration
### at T = -30 C before running the scans
BASELINECALIB=false

### machinery to recover run starting from
### a given channel
RECOVERYMODE=false
RECOVERYCHANNEL=NONE

main()
{
    echo " --- running $1 LED setup "
    
    ### make sure ALCOR is on
    /au/tti/alcor.on
    
    ### check if channel to be recovered is requested
    if [ ! -z $1 ]; then
	RECOVERYMODE=true
	BASELINECALIB=true
	RECOVERYCHANNEL=$1
	echo " --- recovery mode enabled: recover $RECOVERYCHANNEL "
    fi

    ### loop over even target rows
    for row in C; do
	scan_reference
	export AU_BIAS_VOLTAGES=$HAMA2_EVEN_BIAS_VOLTAGES
	export AU_SCAN_BIAS_VOLTAGES=$HAMA2_EVEN_SCAN_BIAS_VOLTAGES
	export AU_CARRIER="hama2"
	scan_row $row;
    done
    
    ### loop over odd target rows
    for row in D; do
	scan_reference
	export AU_BIAS_VOLTAGES=$HAMA2_ODD_BIAS_VOLTAGES
	export AU_SCAN_BIAS_VOLTAGES=$HAMA2_ODD_SCAN_BIAS_VOLTAGES
	export AU_CARRIER="hama2"
	scan_row $row;
    done

    ### loop over even target rows
    for row in E; do
	scan_reference
	export AU_BIAS_VOLTAGES=$HAMA2_EVEN_BIAS_VOLTAGES
	export AU_SCAN_BIAS_VOLTAGES=$HAMA2_EVEN_SCAN_BIAS_VOLTAGES
	export AU_CARRIER="hama2"
	scan_row $row;
    done
    
    ### loop over odd target rows
    for row in F; do
	scan_reference
	export AU_BIAS_VOLTAGES=$HAMA2_ODD_BIAS_VOLTAGES
	export AU_SCAN_BIAS_VOLTAGES=$HAMA2_ODD_SCAN_BIAS_VOLTAGES
	export AU_CARRIER="hama2"
	scan_row $row;
    done

    ### loop over even target rows
    for row in G; do
	scan_reference
	export AU_BIAS_VOLTAGES=$HAMA2_EVEN_BIAS_VOLTAGES
	export AU_SCAN_BIAS_VOLTAGES=$HAMA2_EVEN_SCAN_BIAS_VOLTAGES
	export AU_CARRIER="hama2"
	scan_row $row;
    done
    
    ### loop over odd target rows
    for row in H; do
	scan_reference
	export AU_BIAS_VOLTAGES=$HAMA2_ODD_BIAS_VOLTAGES
	export AU_SCAN_BIAS_VOLTAGES=$HAMA2_ODD_SCAN_BIAS_VOLTAGES
	export AU_CARRIER="hama2"
	scan_row $row;
    done

    ### end run with reference sensor
    scan_reference

    /au/tti/alcor.off
    
    echo " --- THE END "
}

scan_reference()
{
    ### check recovery mode
    if [ $RECOVERYMODE == "true" ]; then
	return
    fi

    export AU_BIAS_VOLTAGES=$HAMA1_EVEN_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA1_EVEN_SCAN_BIAS_VOLTAGES
    export AU_CARRIER="hama1"
    move_to_and_scan 1 A1
}

scan_row()
{    
    ### scan sensors in the target row
    row=$1
    for col in {1..4}; do move_to_and_scan 0 $row$col; done
}

move_to_sensor()
{
    chip=$1
    channel=$2

    ### move to sensor
    date
    echo " --- /au/measure/move_to_sensor_hama2.sh ${chip} ${channel} "
    [ -z "$AU_DRYRUN" ] && time -p /au/measure/move_to_sensor_hama2.sh ${chip} ${channel} &> move.log
    echo " --- "

    ### memmert report
    attachments=$(ls /home/eic/DATA/memmert/PNG/*.png)
    recipients="roberto.preghenella@bo.infn.it"
    mail -r eicdesk01@bo.infn.it \
	 -s "[Memmert] $(basename "`pwd`")" \
	 $(for i in $recipients; do echo "$i,"; done) \
	 $(for i in $attachments; do echo "-A $i"; done) <<EOF
Working from $PWD.
Starting to scan sensor.

(Do not reply, we won't read it)
EOF

}

move_to_and_scan()
{
    chip=$1
    channel=$2

    echo " --- "
    echo " --- doing chip$chip-$2 "
    echo " --- "

    ### check recovery mode, check channel
    if [ $RECOVERYMODE == "true" ]; then
	if [ $RECOVERYCHANNEL == $channel ]; then
	    echo " --- recovery mode disabled: start from channel $channel "
	    RECOVERYMODE=false
	else
	    echo " --- recovery mode continue: skip channel $channel "
	    return
	fi
    fi    
    
    ### create chip scan directory and cd inside
    dir="chip${chip}-${channel}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p ${dir}
    cd ${dir} &> /dev/null

    ### move to sensor
    move_to_sensor $chip $channel
    
    ### make baseline calibration if needed
    if [ $BASELINECALIB == "false" ]; then
	echo " --- /au/measure/2022-characterisation/run-baseline-calibration.sh "
	[ -z "$AU_DRYRUN" ] && time -p /au/measure/2022-characterisation/run-baseline-calibration.sh &> run-baseline-calibration.log
	echo " --- "
#	BASELINECALIB=true
    fi
    
    ### switch ON HV
    /au/tti/hv.on &> /dev/null
    sleep 1
    
    ### scan
    date
    echo " --- /au/measure/scan_hama2.sh ${chip} ${channel} "
    time -p /au/measure/scan_hama2.sh ${chip} ${channel} &> scan.log
    echo " --- "

    ### make summary plot
    echo " --- root /home/eic/alcor/alcor-utils/measure/draw_universal_scan.C "
    root -b -q -l "/home/eic/alcor/alcor-utils/measure/draw_universal_scan.C(\"rate/vbias_scan/chip${chip}-${channel}.vbias_scan.dat.tree.root\", \"bias_voltage\", \"threshold_on - base_threshold == 3 && pulse_voltage == 1000\")"
    echo " --- "

    ### qa
    date
    echo " --- /au/measure/qa.sh ${chip} ${channel} "
    [ -z "$AU_DRYRUN" ] && time -p /au/measure/qa.sh ${chip} ${channel} &> qa.log
    echo " --- "

    ### switch OFF HV
    /au/tti/hv.off &> /dev/null
    sleep 1
    
    ### cd back to root directory
    cd - &> /dev/null
}

main $@
