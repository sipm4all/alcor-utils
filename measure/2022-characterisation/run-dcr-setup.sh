#! /usr/bin/env bash

### standard measurement settings
export AU_BIAS_VOLTAGES="35 37"  # [V]
export AU_DELTA_THRESHOLDS="3 5"
export AU_INTEGRATED_MIN="0.001"   # min integration
export AU_INTEGRATED_MAX="0.1"     # max integration
export AU_COUNT_MAX="400"          # max counts
export AU_REPEAT=25                # repetitions

### scan settings
export AU_SCAN_BIAS_VOLTAGES=$(seq 30 0.5 38 | tr "\n" " ") # [V]
### R+SPEED export AU_SCAN_THRESHOLDS=$(seq 0 3 63 | tr "\n" " ")
export AU_SCAN_THRESHOLDS=$(seq 0 1 63 | tr "\n" " ")

### scans to be performed
export AU_SCANS="vbias threshold"

### uncomment to dry run
# export AU_DRYRUN=true

###
### SENSL scan values
###
SENSL_EVEN_BIAS_VOLTAGES="28.5 30.5"
SENSL_EVEN_SCAN_BIAS_VOLTAGES=$(seq 23.5 0.5 32.5 | tr "\n" " ")
SENSL_ODD_BIAS_VOLTAGES="26.5 28.5"
SENSL_ODD_SCAN_BIAS_VOLTAGES=$(seq 23.5 0.5 32.5 | tr "\n" " ")

###
### BCOM scan values
###
BCOM_BIAS_VOLTAGES="28.5 30.5"
BCOM_SCAN_BIAS_VOLTAGES=$(seq 25.5 0.5 35.5 | tr "\n" " ")

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

main()
{

    echo " --- running $1 DCR setup "
    
    ### make sure firmware is fresh
    /au/firmware/program.sh new 210203A62F62A true
#    /au/firmware/program.sh dev-200mhz 210203A62F62A true
    sleep 3
    
    ### reset masterlogic, we want it in good shape
#    /au/masterlogic/reset 2
#    /au/masterlogic/reset 3
#    sleep 3
    /au/tti/12v.on
    sleep 3
    /au/masterlogic/zero 2
    /au/masterlogic/zero 3
    sleep 3
    
    ### make sure ALCOR is on and pulser is off
    /au/tti/alcor.on
    /au/tti/hv.on
    /au/pulser/off
    sleep 3
 
    echo " --- running baseline calibration: /au/measure/2022-characterisation/run-dcr-baseline-calibration.sh "
    /au/measure/2022-characterisation/run-dcr-baseline-calibration.sh &> run-dcr-baseline-calibration.log
    echo " --- really running $1 DCR setup "
    $1
    
    ### switch off everything
    /au/tti/alcor.off
    /au/tti/hv.off
    /au/tti/12v.off
    sleep 3

}

run-hama-setup()
{
    run-hama1-dcr-scan 2
    run-hama2-dcr-scan 3    
}

run-hama-a-setup()
{
    run-hama1-dcr-scan 2
}

run-hama-chip3-setup()
{
    run-hama1-dcr-scan 3
}

run-sensl-setup()
{
    run-sensl-dcr-scan 2
    run-hama1-light-dcr-scan 3
#    run-bcom-dcr-scan 3
}

run-hamalight-setup()
{
    run-hama1-light-dcr-scan 2
#    run-bcom-dcr-scan 3
}

run-hama2light-setup()
{
    run-hama2-light-dcr-scan 2
#    run-bcom-dcr-scan 3
}

run-fbk-setup()
{
    run-fbk-dcr-scan 2
#    run-fbk-dcr-scan 3
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
	/au/measure/2022-characterisation/draw_dcr_scan.sh $chip 46 62
    done

    export AU_BIAS_VOLTAGES=$HAMA1_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA1_ODD_SCAN_BIAS_VOLTAGES
    for row in B D F H; do
	scan_chip_row $chip $row
	/au/measure/2022-characterisation/draw_dcr_scan.sh $chip 46 62
    done
    
    cd ..

}

run-hama1-light-dcr-scan()
{
    chip=$1

    echo " --- "
    echo " --- running HAMA1L DCR scan on chip $chip "
    echo " --- "
    
    mkdir -p HAMA1L-chip${chip}
    cd HAMA1L-chip${chip}
    export AU_CARRIER="hama1"

    export AU_BIAS_VOLTAGES=$HAMA1_EVEN_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA1_EVEN_SCAN_BIAS_VOLTAGES
    for row in A; do
	scan_chip_half_row $chip $row
    done

    export AU_BIAS_VOLTAGES=$HAMA1_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA1_ODD_SCAN_BIAS_VOLTAGES
    for row in B; do
	scan_chip_half_row $chip $row
    done

    ### DRAW
    /au/measure/2022-characterisation/draw_dcr_scan.sh $chip 46 62
    
    cd ..

}

run-hama2-light-dcr-scan()
{
    chip=$1

    echo " --- "
    echo " --- running HAMA2L DCR scan on chip $chip "
    echo " --- "
    
    mkdir -p HAMA2L-chip${chip}
    cd HAMA2L-chip${chip}
    export AU_CARRIER="hama2"

    export AU_BIAS_VOLTAGES=$HAMA2_EVEN_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA2_EVEN_SCAN_BIAS_VOLTAGES
    for row in A; do
	scan_chip_half_row $chip $row
    done

    export AU_BIAS_VOLTAGES=$HAMA2_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA2_ODD_SCAN_BIAS_VOLTAGES
    for row in B; do
	scan_chip_half_row $chip $row
    done

    ### DRAW
    /au/measure/2022-characterisation/draw_dcr_scan.sh $chip 34 47
    
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
	/au/measure/2022-characterisation/draw_dcr_scan.sh $chip 34 47
    done

    export AU_BIAS_VOLTAGES=$HAMA2_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$HAMA2_ODD_SCAN_BIAS_VOLTAGES
    for row in B D F H; do
	scan_chip_row $chip $row
	/au/measure/2022-characterisation/draw_dcr_scan.sh $chip 34 47
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
	/au/measure/2022-characterisation/draw_dcr_scan.sh $chip 21.5 34.5
    done

    export AU_BIAS_VOLTAGES=$SENSL_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$SENSL_ODD_SCAN_BIAS_VOLTAGES
    for row in B D F H; do
	scan_chip_row $chip $row
	/au/measure/2022-characterisation/draw_dcr_scan.sh $chip 21.5 34.5
    done
    
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
	/au/measure/2022-characterisation/draw_dcr_scan.sh $chip 28 42
    done

    export AU_BIAS_VOLTAGES=$FBK_ODD_BIAS_VOLTAGES
    export AU_SCAN_BIAS_VOLTAGES=$FBK_ODD_SCAN_BIAS_VOLTAGES
    for row in B D F; do
	scan_chip_row $chip $row
	/au/measure/2022-characterisation/draw_dcr_scan.sh $chip 28 42
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
	/au/measure/2022-characterisation/draw_dcr_scan.sh $chip 23.5 37.5
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

scan_chip_half_row()
{    
    ### scan sensors in the target row
    chip=$1
    row=$2
    for col in {1..2}; do
	time -p /au/measure/2022-characterisation/dcr_scan.sh vbias $chip $row$col
	time -p /au/measure/2022-characterisation/dcr_scan.sh threshold $chip $row$col
    done
}

main $1
