#! /usr/bin/env bash

### standard measurement settings
export AU_BIAS_VOLTAGES="35 37"  # [V]
export AU_DELTA_THRESHOLDS="3 5"
export AU_INTEGRATED="0.1"       # pulser_rate integration
export AU_REPEAT=25              # pulse_rate repetitions
export AU_REPEAT=4               # pulse_rate repetitions

### scan settings
export AU_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 38 | tr "\n" " ") # [V]
export AU_SCAN_THRESHOLDS=$(seq 0 3 63 | tr "\n" " ")

### scans to be performed
export AU_SCANS="vbias threshold"

### uncomment to dry run
# export AU_DRYRUN=true

###
### SENSL scan values
###
SENSL_EVEN_BIAS_VOLTAGES="26 27"
SENSL_EVEN_SCAN_BIAS_VOLTAGES=$(seq 22 0.5 34 | tr "\n" " ")
SENSL_ODD_BIAS_VOLTAGES="25 26"
SENSL_ODD_SCAN_BIAS_VOLTAGES=$(seq 22 0.5 34 | tr "\n" " ")

###
### BCOM scan values
###
BCOM_BIAS_VOLTAGES="35 37"
BCOM_SCAN_BIAS_VOLTAGES=$(seq 26 0.5 38 | tr "\n" " ")

###
### FBK scan values
###
FBK_EVEN_BIAS_VOLTAGES="35 37"
FBK_EVEN_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 38 | tr "\n" " ")
FBK_ODD_BIAS_VOLTAGES="37 39"
FBK_ODD_SCAN_BIAS_VOLTAGES=$(seq 32 0.5 40 | tr "\n" " ")

main()
{

    run-bcom-dcr-scan 2

}

run-sensl-dcr-scan()
{
    chip=$1

    echo " --- "
    echo " --- running SENSL DCR scan on chip $chip "
    echo " --- "
    
    mkdir -p SENSL-chip${chip}
    cd SENSL-chip${chip}
    export AU_CARRIER="sensl"

    export AU_BIAS_VOLTAGES=$SENSL_EVEN_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$SENSL_EVEN_SCAN_BIAS_VOLTAGES
    for row in A C E G; do
	scan_chip_row $chip $row
    done

    export AU_BIAS_VOLTAGES=$SENSL_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$SENSL_ODD_SCAN_BIAS_VOLTAGES
    for row in B D F H; do
	scan_chip_row $chip $row
    done
    
    cd ..

}

run-bcom-dcr-scan()
{
    chip=$1

    echo " --- "
    echo " --- running BCOM DCR scan on chip $chip "
    echo " --- "
    
    mkdir -p BCOM-chip${chip}
    cd BCOM-chip${chip}
    export AU_CARRIER="bcom"

    export AU_BIAS_VOLTAGES=$BCOM_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$BCOM_SCAN_BIAS_VOLTAGES
    for row in A B C D E F G H; do
	scan_chip_row $chip $row
    done
    
    cd ..

}

run-sensl-dcr-scan()
{
    chip=$1

    echo " --- "
    echo " --- running FBK DCR scan on chip $chip "
    echo " --- "
    
    mkdir -p FBK-chip${chip}
    cd FBK-chip${chip}
    export AU_CARRIER="fbk"

    export AU_BIAS_VOLTAGES=$FBK_EVEN_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$FBK_EVEN_SCAN_BIAS_VOLTAGES
    for row in A C E G; do
	scan_chip_row $chip $row
    done

    export AU_BIAS_VOLTAGES=$FBK_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$FBK_ODD_SCAN_BIAS_VOLTAGES
    for row in B D F H; do
	scan_chip_row $chip $row
    done
    
    cd ..

}

scan_chip_row()
{    
    ### scan sensors in the target row
    chip=$1
    row=$2
    for col in {1..4}; do
	time -p /au/measure/2022-characterisation/dcr_scan.sh vbias $chip $row$col
	time -p /au/measure/2022-characterisation/dcr_scan.sh threshold $chip $row$col
    done
}

scan()
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
OB
    
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
