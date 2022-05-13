#! /usr/bin/env bash

### standard measurement settings
export AU_TEMPERATURE="-30"             # [C]
export AU_PULSE_VOLTAGES="960 980 1000" # [mV]
export AU_PULSE_FREQUENCIES="100"       # [kHz]
export AU_BIAS_REF_VOLTAGES="54 56"     # [V @ T = 20C]
export AU_DELTA_THRESHOLDS="3 5"
export AU_INTEGRATED="0.1"              # pulser_rate integration
export AU_REPEAT=25                     # pulse_rate repetitions
export AU_UINTEGRATED="1"               # ureadout integration
export AU_UREPEAT=5                     # ureadout repetitions

### test measurement settings
export AU_TEST_PULSE_VOLTAGES="960"     # [mV]
export AU_TEST_PULSE_FREQUENCIES="100"  # [kHz]
export AU_TEST_BIAS_REF_VOLTAGES="54"   # [V @ T = 20C]
export AU_TEST_DELTA_THRESHOLDS="3"

### scan settings
export AU_SCAN_BIAS_REF_VOLTAGES=$(seq 51 0.5 59 | tr "\n" " ") # [V @ T = 20C]
export AU_SCAN_THRESHOLDS=$(seq 0 3 63 | tr "\n" " ")
export AU_SCAN_PULSE_FREQUENCIES="100 50 10"

### scans to be performed
export AU_SCANS="vbias threshold frequency"

### uncomment to dry run
# export AU_DRYRUN=true

main()
{
    ### sleep 3 hours
    sleep 3h
    
    ### do reference sensor
    move_to_and_scan 0 C3

    echo " --- THE END "
}

scan_row()
{    
    ### start each row with reference sensor
    move_to_and_scan 1 A1

    ### scan sensors in the target row
    row=$1
    for col in {1..4}; do move_to_and_scan 0 $row$col; done
}

move_to_and_scan()
{
    chip=$1
    channel=$2

    ### create chip scan directory and cd inside
    dir="chip${chip}-${channel}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p ${dir}
    cd ${dir} &> /dev/null

    ### memmert report
    attachments=$(ls /home/eic/DATA/memmert/PNG/*.png)
    recipients="roberto.preghenella@bo.infn.it nicola.rubini@bo.infn.it"
    mail -r eicdesk01@bo.infn.it \
	 -s "[Memmert] $(basename "`pwd`")" \
	 $(for i in $recipients; do echo "$i,"; done) \
	 $(for i in $attachments; do echo "-A $i"; done) <<EOF
Working from $PWD.
Starting to scan sensor.

(Do not reply, we won't read it)
EOF

    
    ### scan
    date
    echo " --- /au/measure/scan.sh ${chip} ${channel} "
    time -p /au/measure/scan.sh ${chip} ${channel} &> scan.log
    echo " --- "

    ### qa
    date
    echo " --- /au/measure/qa.sh ${chip} ${channel} "
    [ -z "$AU_DRYRUN" ] && time -p /au/measure/qa.sh ${chip} ${channel} &> qa.log
    echo " --- "

    ### cd back to root directory
    cd - &> /dev/null
}

main
