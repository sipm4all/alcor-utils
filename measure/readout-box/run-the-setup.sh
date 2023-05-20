#! /usr/bin/env bash

SETUP=""
CHIP=""

if [ -z $1 ] ; then
    echo "usage: $0 [setup] [start-time]"
    echo " hama1, hama2, sensl, fbk "
    exit 1
fi
SETUP=$1
STARTTIME=$2

DIRNAME=$PWD/$SETUP

WHAT_DCR_SETUP=""
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
    
    "cosenza")
	WHAT_DCR_SETUP="run-cosenza-setup"
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

### wait till good time to start
# R+matilde sleep $(( $(date -d ${STARTTIME} +%s) - $(date +%s) ))

echo " --- "
echo " --- START: $DIRNAME "
echo " --- "
echo "$(date +%s) | $(date) "
echo " --- "

### anchor Peltier PID control on current chip
# R+matilde echo " --- anchoring Peltier PID control on Masterlogic ${CHIP}"
# R+matilde /au/peltier-bologna/peltier_pid_control_client.py "anchor ml${CHIP}"

### make sure temperature is reached
# R+matilde echo " --- waiting for -30 C on Masterlogic $CHIP"
# R+matilde /au/measure/readout-box/temperature_wait.py --ml $CHIP --tset -30 --time 1800 --sleep 10 &> temperature_wait.log

###################################################################

echo " --- "
echo " --- SCAN: $DIRNAME "
echo " --- "
echo "$(date +%s) | $(date) "
echo " --- "

DCRDIRNAME=$DIRNAME/dcr

### run dcr setup
if [ ! -x $WHAT_DCR_SETUP ]; then
    mkdir -p $DCRDIRNAME
    cd $DCRDIRNAME
    echo " --- starting DCR setup: /au/measure/readout-box/run-dcr-setup.sh ${WHAT_DCR_SETUP}"
    nohup /au/measure/readout-box/run-dcr-setup.sh ${WHAT_DCR_SETUP} &> run-dcr-setup.log < /dev/null &
    cd - &> /dev/null
fi

echo " --- waiting for processes to complete "
wait

echo " --- "
echo " --- COMPLETED: $DIRNAME "
echo " --- "
echo "$(date +%s) | $(date) "
echo " --- "

### clean token
rm -rf /tmp/run-the-setup.running

echo " --- "
echo " --- DONE: $DIRNAME "
echo " --- "
echo "$(date +%s) | $(date) "
echo " --- "
