#! /usr/bin/env bash

### standard measurement settings
export AU_BIAS_VOLTAGES="35 37"  # [V]
# R+speedup export AU_DELTA_THRESHOLDS="3 5"
export AU_DELTA_THRESHOLDS="5"
export AU_INTEGRATED="0.1"       # pulser_rate integration
export AU_REPEAT=25              # pulse_rate repetitions
#export AU_REPEAT=5
#export AU_REPEAT=4
#export AU_REPEAT=2

### scan settings
export AU_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 38 | tr "\n" " ") # [V]
export AU_SCAN_THRESHOLDS=$(seq 0 3 63 | tr "\n" " ")

### scans to be performed
export AU_SCANS="vbias threshold"
# export AU_SCANS="threshold"

### uncomment to dry run
# export AU_DRYRUN=true

###
### SENSL scan values
###
# R+matilde SENSL_EVEN_BIAS_VOLTAGES="28.5 30.5"
SENSL_EVEN_BIAS_VOLTAGES="27 28"
SENSL_EVEN_SCAN_BIAS_VOLTAGES=$(seq 23.5 0.5 32.5 | tr "\n" " ")
# R+matilde SENSL_ODD_BIAS_VOLTAGES="26.5 28.5"
SENSL_ODD_BIAS_VOLTAGES="26 27"
SENSL_ODD_SCAN_BIAS_VOLTAGES=$(seq 23.5 0.5 32.5 | tr "\n" " ")

###
### BCOM scan values
###
BCOM_BIAS_VOLTAGES="28.5 30.5"
BCOM_SCAN_BIAS_VOLTAGES=$(seq 25.5 0.5 35.5 | tr "\n" " ")

###
### FBK scan values
###
# R+matilde FBK_EVEN_BIAS_VOLTAGES="33 35"
# R+speedup FBK_EVEN_BIAS_VOLTAGES="35 36"
FBK_EVEN_BIAS_VOLTAGES="35"
FBK_EVEN_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 38 | tr "\n" " ")
# R+matilde FBK_ODD_BIAS_VOLTAGES="35 37"
# R+speedup FBK_ODD_BIAS_VOLTAGES="37 38"
FBK_ODD_BIAS_VOLTAGES="38"
FBK_ODD_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 40 | tr "\n" " ")

###
### HAMA1 scan values
###
# R+matilde HAMA1_EVEN_BIAS_VOLTAGES="51 53"
# R+speedup HAMA1_EVEN_BIAS_VOLTAGES="50 51"
HAMA1_EVEN_BIAS_VOLTAGES="51"
HAMA1_EVEN_SCAN_BIAS_VOLTAGES=$(seq 48 0.5 58 | tr "\n" " ")
# R+matilde HAMA1_ODD_BIAS_VOLTAGES="53 55"
# R+speedup HAMA1_ODD_BIAS_VOLTAGES="53 54"
HAMA1_ODD_BIAS_VOLTAGES="53"
HAMA1_ODD_SCAN_BIAS_VOLTAGES=$(seq 48 0.5 60 | tr "\n" " ")

###
### HAMA2 scan values
###
# R+matilde HAMA2_EVEN_BIAS_VOLTAGES="39 41"
# R+speedup HAMA2_EVEN_BIAS_VOLTAGES="39 40"
HAMA2_EVEN_BIAS_VOLTAGES="39"
HAMA2_EVEN_SCAN_BIAS_VOLTAGES=$(seq 36 0.5 43 | tr "\n" " ")
# R+matilde HAMA2_ODD_BIAS_VOLTAGES="41 43"
# R+speedup HAMA2_ODD_BIAS_VOLTAGES="43 44"
HAMA2_ODD_BIAS_VOLTAGES="43"
HAMA2_ODD_SCAN_BIAS_VOLTAGES=$(seq 36 0.5 45 | tr "\n" " ")

main()
{
    
    echo " --- running $1 DCR setup "

    ### stop rate monitor if running
    /au/measure/readout-box/stop_rate_monitor.sh
    
    ### make sure firmware is fresh
# R+matilde    /au/firmware/program.sh new $KC705_TARGET true
    /au/firmware/program.sh dev $KC705_TARGET true
    sleep 3
   
    ### reset masterlogic, we want it in good shape
#    /au/masterlogic/reset 2
#   /au/masterlogic/reset 3
#    sleep 3
    /au/masterlogic/zero 0
    /au/masterlogic/zero 1
    /au/masterlogic/zero 2
    /au/masterlogic/zero 3
    sleep 3
    
    ### make sure ALCOR is on and pulser is off
#    /au/tti/alcor.on
#   /au/tti/12v.on
#    /au/tti/hv.on
#    /au/pulser/off
#    sleep 3
 
    ### run baseline calibration
# R+matilde    echo " --- running baseline calibration: /au/measure/readout-box/run-dcr-baseline-calibration.sh "
# R+matilde    echo " --- "
# R+matilde    echo "$(date +%s) | $(date) "
# R+matilde    echo " --- "
# R+matilde    /au/measure/readout-box/run-dcr-baseline-calibration.sh &> run-dcr-baseline-calibration.log
    
#    echo " --- running baseline calibration: /au/measure/readout-box/run-box-baseline-calibration.sh "
#    echo " --- "
#    echo "$(date +%s) | $(date) "
#    echo " --- "
#    /au/measure/readout-box/run-box-baseline-calibration.sh &> run-box-baseline-calibration.log

    ### make sure temperature is reached
# R+matilde    echo " --- waiting 30 minutes"
# R+matilde    echo " --- "
# R+matilde    echo "$(date +%s) | $(date) "
# R+matilde    echo " --- "
# R+matilde    sleep 1800

    ### link baseline readout.conf
    ln -sf /au/conf/readout.baseline.conf /au/conf/readout.conf
    
    echo " --- really running $1 DCR setup "
    echo " --- "
    echo "$(date +%s) | $(date) "
    echo " --- "
    $1
    
    ### link back run readout.conf
    ln -sf /au/conf/readout.run.conf /au/conf/readout.conf
    
    ### switch off everything
#    /au/tti/alcor.off
#    /au/tti/hv.off
#    /au/tti/12v.off
#    sleep 3

}

run-hama1-setup()
{
    run-hama1-dcr-scan 0    
}

run-hama1-bis-setup()
{
    run-hama1-dcr-scan 3    
}

run-hama2-setup()
{
    run-hama2-dcr-scan 2    
}

run-sensl-setup()
{
    run-sensl-dcr-scan 3
}

run-fbk-setup()
{
    run-fbk-dcr-scan 1
}

run-hama1-dcr-scan()
{
    chip=$1

    echo " --- "
    echo " --- running HAMA1 DCR scan on chip $chip "
    echo " --- "
    
    mkdir -p HAMA1-chip${chip}
    cd HAMA1-chip${chip}
    export AU_CARRIER="hama1"

    export AU_BIAS_VOLTAGES=$HAMA1_EVEN_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA1_EVEN_SCAN_BIAS_VOLTAGES
    for row in A C E G; do
	scan_chip_row $chip $row
	/au/measure/readout-box/draw_dcr_scan.sh $chip 46 62
    done

    export AU_BIAS_VOLTAGES=$HAMA1_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA1_ODD_SCAN_BIAS_VOLTAGES
    for row in B D F H; do
	scan_chip_row $chip $row
	/au/measure/readout-box/draw_dcr_scan.sh $chip 46 62
    done

    ### DRAW
    /au/measure/readout-box/draw_dcr_scan.sh $chip 46 62
    
    cd ..

}

run-hama2-dcr-scan()
{
    chip=$1

    echo " --- "
    echo " --- running HAMA2 DCR scan on chip $chip "
    echo " --- "
    
    mkdir -p HAMA2-chip${chip}
    cd HAMA2-chip${chip}
    export AU_CARRIER="hama2"

    export AU_BIAS_VOLTAGES=$HAMA2_EVEN_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA2_EVEN_SCAN_BIAS_VOLTAGES
    for row in A C E G; do
	scan_chip_row $chip $row
    done

    export AU_BIAS_VOLTAGES=$HAMA2_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA2_ODD_SCAN_BIAS_VOLTAGES
    for row in B D F H; do
	scan_chip_row $chip $row
    done
    
    ### DRAW
    /au/measure/readout-box/draw_dcr_scan.sh $chip 34 47
    
    cd ..

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
    
    ### DRAW
    /au/measure/readout-box/draw_dcr_scan.sh $chip 21.5 34.5
    
    cd ..

}

run-fbk-dcr-scan()
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
    for row in A C E; do
	scan_chip_row $chip $row
    done

    export AU_BIAS_VOLTAGES=$FBK_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$FBK_ODD_SCAN_BIAS_VOLTAGES
    for row in B D F; do
	scan_chip_row $chip $row
    done
    
    ### DRAW
    /au/measure/readout-box/draw_dcr_scan.sh $chip 28 42
    
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
    
    ### DRAW
    /au/measure/readout-box/draw_dcr_scan.sh $chip 23.5 37.5
    
    cd ..

}

scan_chip_row()
{    
    ### scan sensors in the target row
    chip=$1
    row=$2
    for col in {1..4}; do
	for scan in $AU_SCANS; do
	    time -p /au/measure/readout-box/dcr_scan.sh $scan $chip $row$col
#	    time -p /au/measure/readout-box/dcr_scan.sh vbias $chip $row$col
#	    time -p /au/measure/readout-box/dcr_scan.sh threshold $chip $row$col
	done
    done
}

### check input parameters
if [ -x $1 ]; then
    echo "usage: $0 [run setup]"
    echo " run-hama1-setup, run-hama2-setup, run-sensl-setup, run-fbk-setup"
    exit 1
fi

main $1

