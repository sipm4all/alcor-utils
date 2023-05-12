#! /usr/bin/env bash

### allow batch processing and plotting at the same time
export PYTHONUNBUFFERED=1
export MPLBACKEND=Agg
nmeas=9
nmeas_open=4

ROWS="A B C D E F G H"
COLS="1 2 3 4"

main()
{
    echo " --- running $1 IV setup "
    $1
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

run-memmert-hama3-setup()
{
    ### HAMA3
    ROWS="A B C"
    COLS="1 2 3 4"
    run_scan HAMA3 0 1 ### board, serial, mux
    run_scan HAMA3 0 2 ### board, serial, mux
}

run-hama-setup()
{
    ### HAMA1/HAMA2
    ROWS="A B C D E F G H"
    COLS="1 2 3 4"
    run_scan HAMA1 2 1 ### board, serial, mux
    run_scan HAMA2 2 2 ### board, serial, mux
}

run-sensl-setup()
{
    ### BCOM/SENSL (nein)
    ### BCOM/HAMA1L

    ROWS="A B C D E F G H"
    COLS="1 2 3 4"
    run_scan SENSL 1 1 ### board, serial, mux

    ROWS="A B"
    COLS="1 2"
    run_scan HAMA1 4 2 ### board, serial, mux
}

run-fbk-setup()
{
    ### FBK
    ROWS="A B C D E F"
    COLS="1 2 3 4"
    run_scan FBK 1 1 ### board, serial, mux
    run_scan FBK 2 2 ### board, serial, mux
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
    
    for row in $ROWS; do
	for col in $COLS; do
	    ch=$row$col
	    echo $ch

	    ### do open first
#	    echo "$(echo Data | ncat 10.0.8.101 3482)" > ${board}_sn${serial}_243K_OPEN-$ch.temprh
	    /au/keithley/keithley_multiplexer_cmd.py "ROUTE:OPEN:ALL"
	    /au/keithley/ivscan.py --temperature 243 --vstep 2. --nmeas $nmeas_open --board $board --serial $serial --channel OPEN-$ch
	    
	    ### then close and do channel
#	    echo "$(echo Data | ncat 10.0.8.101 3482)" > ${board}_sn${serial}_243K_$ch.temprh
	    /au/keithley/keithley_multiplexer_close.sh $mux $ch
	    /au/keithley/ivscan.py --temperature 243 --nmeas $nmeas --board $board --serial $serial --channel $ch

	done

	### draw results
	/au/measure/2023-characterisation/draw_iv.sh ${board}_sn${serial}_243K
	
    done

    cd ..
}

main $1
