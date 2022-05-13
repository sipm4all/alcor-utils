#! /usr/bin/env bash

### allow batch processing and plotting at the same time
export PYTHONUNBUFFERED=1
export MPLBACKEND=Agg

nmeas=25
nmeas=4

main()
{
    run_fbk_setup
}

create_config_keithley()
{
cat <<EOF > config.keithley
SYST:RSEN OFF
ROUT:TERM FRONT

SENS:FUNC "CURR"
SENS:CURR:AZER ON
SENS:CURR:NPLC 1.
SENS:CURR:RANG:AUTO ON
SENS:CURR:AVER:COUNT 1
SENS:CURR:AVER:TCON REP
SENS:CURR:AVER ON

SOUR:FUNC VOLT
SOUR:VOLT:READ:BACK OFF
SOUR:VOLT:DEL:AUTO ON
#SOUR:VOLT:RANG:AUTO ON
SOUR:VOLT:RANG 200
SOUR:VOLT:ILIM 25.e-6
EOF
}

run_hama_setup()
{
    ### HAMA1/HAMA2
#    run_scan HAMA1 1 1 ### board, serial, mux
    run_scan HAMA2 1 2 ### board, serial, mux
}

run_bcom_setup()
{
    ### BCOM/SENSL
    run_scan BCOM  1 1 ### board, serial, mux
    run_scan SENSL 1 2 ### board, serial, mux
}

run_fbk_setup()
{
    ### FBK
    run_scan FBK 10 1 ### board, serial, mux
    run_scan FBK 11 2 ### board, serial, mux
}

run_scan()
{
    board=$1
    serial=$2
    mux=$3
    dir=${board}_sn${serial}_mux${mux}
    mkdir -p $dir
    cd $dir
    create_config_keithley
    
    /au/keythley/keythley_multiplexer_cmd.py "ROUTE:OPEN:ALL"
    timeout 3600 /home/eic/alcor/sipm4eic/characterisation/keithley/ivscan.py --temperature 243 --nmeas $nmeas --board $board --serial $serial --channel OPEN
    for row in A B C D E F G H; do
	for col in 1 2 3 4; do
	    ch=$row$col
	    echo $ch
	    /au/keythley/keythley_multiplexer_close.sh $mux $ch
	    timeout 3600 /home/eic/alcor/sipm4eic/characterisation/keithley/ivscan.py --temperature 243 --nmeas $nmeas --board $board --serial $serial --channel $ch
	done
    done

    cd ..
}

main
