#! /usr/bin/env bash

TYPE=""
STEP=""

if [ -z $1 ] || [ -z $2 ] ; then
    echo "usage: $0 [NEW/IRR/ANN] [STEP]"
    exit 1
fi
TYPE=$1
STEP=$2

DIRNAME=$PWD/$TYPE/$STEP

WHAT_IV_SETUP=""
WHAT_DCR_SETUP=""
WHAT_LED_SETUP=""
case $STEP in
    "1")
	WHAT_IV_SETUP="run-hama-setup"
	WHAT_DCR_SETUP="run-fbk-setup"
	;;
    
    "1iv")
	WHAT_IV_SETUP="run-hama-setup"
	;;
    
    "1a")
	WHAT_IV_SETUP="run-hama-a-setup"
	;;
    
    "1chip3")
	WHAT_DCR_SETUP="run-hama-chip3-setup"
	;;
    
    "1s")
	WHAT_IV_SETUP="run-fbk-setup"
	WHAT_DCR_SETUP="run-hama-setup"
	;;
    
    "2")
	WHAT_IV_SETUP="run-sensl-setup"
	WHAT_DCR_SETUP="run-hama-setup"
	;;
    
    "2a")
	WHAT_DCR_SETUP="run-hama-a-setup"
	;;
    
    "2L")
	WHAT_IV_SETUP="run-hamalight-setup"
	WHAT_DCR_SETUP=""
	;;
    
    "3")
	WHAT_IV_SETUP="run-fbk-setup"	
	WHAT_DCR_SETUP="run-sensl-setup"	
	;;
    
    "3L")
	WHAT_IV_SETUP=""	
	WHAT_DCR_SETUP="run-hamalight-setup"	
	;;
    
    "4")
	WHAT_LED_SETUP="run-hama1-setup"	
	;;
    
    "5")
#	WHAT_IV_SETUP="run-bcom-setup"	
	WHAT_DCR_SETUP="run-hamalight-setup"	
#	WHAT_DCR_SETUP="run-sensl-setup"	
	;;
    
    "6")
	WHAT_DCR_SETUP="run-hama2light-setup"	
	;;
    
    *)
	echo " invalid step: $2 "
	exit 1
	;;
esac

### check token
if [ -f "/tmp/run-the-setup.running" ]; then
    echo " --- there is already a running THE setup: $(cat /tmp/run-the-setup.running)"
    exit 1
fi
echo "$$ $DIRNAME" > /tmp/run-the-setup.running

echo " --- "
echo " --- START: $DIRNAME "
echo " --- "
echo "$(date +%s) | $(date) "
echo " --- "

### make sure LED is on reference before lowering temperature
echo " --- move to reference sensor: /au/standa/move_to_reference.sh "
#/au/standa/move_to_reference.sh &> move_to_reference.log

### make sure RH and temperature are reached
echo " --- go to -30 C: /au/memmert/memmert_go_to_minus_30.sh "
/au/memmert/memmert_go_to_minus_30.sh &> go_to_minus_30.log

###################################################################

echo " --- "
echo " --- SCAN: $DIRNAME "
echo " --- "
echo "$(date +%s) | $(date) "
echo " --- "

IVDIRNAME=$DIRNAME/iv
DCRDIRNAME=$DIRNAME/dcr
LEDDIRNAME=$DIRNAME/led

### run iv setup
if [ ! -x $WHAT_IV_SETUP ]; then
    mkdir -p $IVDIRNAME
    cd $IVDIRNAME
    echo " --- starting IV setup: /au/measure/2022-characterisation/run-iv-setup.sh ${WHAT_IV_SETUP}"
    nohup time -p /au/measure/2022-characterisation/run-iv-setup.sh ${WHAT_IV_SETUP} &> run-iv-setup.log < /dev/null &
    cd - &> /dev/null
fi

### run dcr setup
if [ ! -x $WHAT_DCR_SETUP ]; then
    mkdir -p $DCRDIRNAME
    cd $DCRDIRNAME
    echo " --- starting DCR setup: /au/measure/2022-characterisation/run-dcr-setup.sh ${WHAT_DCR_SETUP}"
    nohup time -p /au/measure/2022-characterisation/run-dcr-setup.sh ${WHAT_DCR_SETUP} &> run-dcr-setup.log < /dev/null &
    cd - &> /dev/null
fi

### run led setup
if [ ! -x $WHAT_LED_SETUP ]; then
    mkdir -p $LEDDIRNAME
    cd $LEDDIRNAME
    echo " --- starting LED setup: /au/measure/2022-characterisation/run-led-scan.sh ${WHAT_LED_SETUP}"
    nohup time -p /au/measure/2022-characterisation/run-led-scan.sh ${WHAT_DCR_SETUP} &> run-led-scan.log < /dev/null &
    cd - &> /dev/null
fi

echo " --- waiting for processes to complete "
wait

echo " --- "
echo " --- COMPLETED: $DIRNAME "
echo " --- "
echo "$(date +%s) | $(date) "
echo " --- "

### switch off everything
echo " --- switch off everything "
/au/tti/alcor.off &> /dev/null
/au/tti/hv.off &> /dev/null
/au/tti/12v.off &> /dev/null
/home/eic/alcor/sipm4eic/characterisation/keithley/checkcomm.py &> /dev/null
sleep 2

### go back to 20 C
echo " --- go back to 20 C: /au/memmert/memmert_back_to_plus_20.sh "
/au/memmert/memmert_back_to_plus_20.sh &> back_to_plus_20.log

### clean token
rm -rf /tmp/run-the-setup.running

echo " --- "
echo " --- DONE: $DIRNAME "
echo " --- "
echo "$(date +%s) | $(date) "
echo " --- "
