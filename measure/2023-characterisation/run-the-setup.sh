#! /usr/bin/env bash

SETUP=""
CHIP=""

if [ -z $1 ] ; then
    echo "usage: $0 [setup]"
    echo " memmert-hama3 "
    exit 1
fi
SETUP=$1

DIRNAME=$PWD/$SETUP

WHAT_IV_SETUP=""
WHAT_DCR_SETUP=""
WHAT_LED_SETUP=""
case $SETUP in
    "hama1")
	WHAT_DCR_SETUP="run-hama1-setup"
	CHIP=0
	;;
    
    "hama1-bis")
	WHAT_DCR_SETUP="run-hama1-bis-setup"
	CHIP=3
	;;
    
    "hama2")
	WHAT_DCR_SETUP="run-hama2-setup"
	CHIP=2
	;;
    
    "fbk")
	WHAT_DCR_SETUP="run-fbk-setup"
	CHIP=1
	;;
    
    "sensl")
	WHAT_DCR_SETUP="run-sensl-setup"
	CHIP=3
	;;

    "tot")
	WHAT_DCR_SETUP="run-tot-setup"
	CHIP=0
	;;
    
    "memmert-hama3")
	WHAT_DCR_SETUP="run-memmert-hama3-setup"
	WHAT_IV_SETUP="run-memmert-hama3-setup"
	CHIP=0
	;;
    
    *)
	echo " invalid setup: $1 "
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

### setup-dependent start-up
case $SETUP in
  *"memmert"*)
      ### make sure RH and temperature are reached
      echo " --- go to -30 C: /au/memmert/memmert_go_to_minus_30.sh "
      /au/memmert/memmert_go_to_minus_30.sh &> go_to_minus_30.log
    ;;
esac

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
    echo " --- starting IV setup: /au/measure/2023-characterisation/run-iv-setup.sh ${WHAT_IV_SETUP}"
    nohup time -p /au/measure/2023-characterisation/run-iv-setup.sh ${WHAT_IV_SETUP} &> run-iv-setup.log < /dev/null &
    cd - &> /dev/null
fi

### run dcr setup
if [ ! -x $WHAT_DCR_SETUP ]; then
    mkdir -p $DCRDIRNAME
    cd $DCRDIRNAME
    echo " --- starting DCR setup: /au/measure/2023-characterisation/run-dcr-setup.sh ${WHAT_DCR_SETUP}"
    nohup time -p /au/measure/2023-characterisation/run-dcr-setup.sh ${WHAT_DCR_SETUP} &> run-dcr-setup.log < /dev/null &
    cd - &> /dev/null
fi

### run led setup
if [ ! -x $WHAT_LED_SETUP ]; then
    mkdir -p $LEDDIRNAME
    cd $LEDDIRNAME
    echo " --- starting LED setup: /au/measure/2023-characterisation/run-led-scan.sh ${WHAT_LED_SETUP}"
    nohup time -p /au/measure/2023-characterisation/run-led-scan.sh ${WHAT_DCR_SETUP} &> run-led-scan.log < /dev/null &
    cd - &> /dev/null
fi

echo " --- waiting for processes to complete "
wait

echo " --- "
echo " --- COMPLETED: $DIRNAME "
echo " --- "
echo "$(date +%s) | $(date) "
echo " --- "

### setup-dependent close-up
case $SETUP in
  *"memmert"*)
      ### go back to 20 C
      echo " --- go back to 20 C: /au/memmert/memmert_back_to_plus_20.sh "
      /au/memmert/memmert_back_to_plus_20.sh &> back_to_plus_20.log
    ;;
esac

### clean token
rm -rf /tmp/run-the-setup.running

echo " --- "
echo " --- DONE: $DIRNAME "
echo " --- "
echo "$(date +%s) | $(date) "
echo " --- "
