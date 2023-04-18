#! /usr/bin/env bash

### standard measurement settings
export AU_BIAS_VOLTAGES="35 37"  # [V]
export AU_DELTA_THRESHOLDS="5"
export AU_INTEGRATED="0.5"
export AU_REPEAT=1

### scan settings
export AU_OPMODE=1
export AU_DELETE_RAW_DATA=true
export AU_RUN_ANALYSIS=true
export AU_DELETE_DECODED_DATA=true
export AU_SCAN_BIAS_STEP="0.5"
export AU_SCAN_BIAS_VOLTAGES=$(seq 30 $AU_SCAN_BIAS_STEP 38 | tr "\n" " ") # [V]
export AU_SCAN_DELTA_THRESHOLDS=$(seq 1 2 63 | tr "\n" " ")

### scans to be performed
export AU_SCANS="vbias threshold"

### uncomment to dry run
# export AU_DRYRUN=true

###
### SENSL scan values
###
SENSL_EVEN_BIAS_VOLTAGES="27 28"
SENSL_EVEN_SCAN_BIAS_VOLTAGES=$(seq 23.5 $AU_SCAN_BIAS_STEP 32.5 | tr "\n" " ")
SENSL_ODD_BIAS_VOLTAGES="26 27"
SENSL_ODD_SCAN_BIAS_VOLTAGES=$(seq 23.5 $AU_SCAN_BIAS_STEP 32.5 | tr "\n" " ")

###
### BCOM scan values
###
BCOM_BIAS_VOLTAGES="28.5 30.5"
BCOM_SCAN_BIAS_VOLTAGES=$(seq 25.5 $AU_SCAN_BIAS_STEP 35.5 | tr "\n" " ")

###
### FBK scan values
###
FBK_EVEN_BIAS_VOLTAGES="35"
FBK_EVEN_SCAN_BIAS_VOLTAGES=$(seq 30 $AU_SCAN_BIAS_STEP 38 | tr "\n" " ")
FBK_ODD_BIAS_VOLTAGES="38"
FBK_ODD_SCAN_BIAS_VOLTAGES=$(seq 30 $AU_SCAN_BIAS_STEP 40 | tr "\n" " ")

###
### HAMA1 scan values
###
HAMA1_EVEN_BIAS_VOLTAGES="51"
HAMA1_EVEN_SCAN_BIAS_VOLTAGES=$(seq 48 $AU_SCAN_BIAS_STEP 58 | tr "\n" " ")
HAMA1_ODD_BIAS_VOLTAGES="53"
HAMA1_ODD_SCAN_BIAS_VOLTAGES=$(seq 48 $AU_SCAN_BIAS_STEP 60 | tr "\n" " ")

###
### HAMA2 scan values
###
HAMA2_EVEN_BIAS_VOLTAGES="39"
HAMA2_EVEN_SCAN_BIAS_VOLTAGES=$(seq 36 $AU_SCAN_BIAS_STEP 43 | tr "\n" " ")
HAMA2_ODD_BIAS_VOLTAGES="43"
HAMA2_ODD_SCAN_BIAS_VOLTAGES=$(seq 38 $AU_SCAN_BIAS_STEP 45 | tr "\n" " ")


main()
{
    
    echo " --- running $1 DCR setup  "

    ### stop rate monitor if running
#    /au/measure/readout-box/stop_rate_monitor.sh
    
    ### make sure firmware is fresh
    /au/firmware/program.sh new $KC705_TARGET true
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
#    run-hama2-dcr-scan 2    
    run-hama2-dcr-scan 0
}

run-tot-setup()
{
    run-tot-dcr-scan 0
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
	/au/measure/2023-characterisation/draw_dcr_scan.sh $chip 46 62
    done

    export AU_BIAS_VOLTAGES=$HAMA1_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA1_ODD_SCAN_BIAS_VOLTAGES
    for row in B D F H; do
	scan_chip_row $chip $row
	/au/measure/2023-characterisation/draw_dcr_scan.sh $chip 46 62
    done

    ### DRAW
    /au/measure/2023-characterisation/draw_dcr_scan.sh $chip 46 62
    
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
#    /au/measure/readout-box/draw_dcr_scan.sh $chip 34 47
    
    cd ..

}

run-tot-dcr-scan()
{
    chip=$1

    echo " --- "
    echo " --- running TOT DCR scan on chip $chip "
    echo " --- "
    
    export AU_CARRIER="hama1"

    export AU_OPMODE=4
    export AU_DELETE_RAW_DATA=true
    export AU_RUN_ANALYSIS=false
    export AU_DELETE_DECODED_DATA=false

    ### vbias scan parameters
    export AU_SCAN_BIAS_VOLTAGES=51
    export AU_DELTA_THRESHOLDS=5
    ### threshold scan parameters
    export AU_SCAN_DELTA_THRESHOLDS="3 5 7"
    export AU_BIAS_VOLTAGES="51 52 53"

    export AU_SCANS="threshold"
    
    mkdir -p HAMA1-chip${chip}
    cd HAMA1-chip${chip}

    for scan in $AU_SCANS; do
	time -p /au/measure/2023-characterisation/ureadout_dcr_scan.sh $scan $chip A1
    done
    
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
#    /au/measure/readout-box/draw_dcr_scan.sh $chip 21.5 34.5
    
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
#    /au/measure/readout-box/draw_dcr_scan.sh $chip 28 42
    
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
#    /au/measure/readout-box/draw_dcr_scan.sh $chip 23.5 37.5
    
    cd ..

}

scan_chip_row()
{    
    ### scan sensors in the target row
    chip=$1
    row=$2
    for col in {1..4}; do
	for scan in $AU_SCANS; do
	    time -p /au/measure/2023-characterisation/ureadout_dcr_scan.sh $scan $chip $row$col
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

