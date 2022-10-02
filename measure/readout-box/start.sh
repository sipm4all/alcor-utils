#! /usr/bin/env bash

STARTTIME="22:00"
if [ -z $1 ]; then
    echo "usage: $0 [setup] [start-time]"
    echo " hama1, hama2, sensl, fbk "
    exit 1
fi

if [ ! -z $2 ]; then
    STARTTIME=$2
fi


### check token
if [ -f "/tmp/run-the-setup.running" ]; then
    echo " --- there is already a running THE setup: $(cat /tmp/run-the-setup.running)"
    exit 1
fi

DATETIME=$(date +%Y%m%d-%H%M%S)

DIRNAME=/home/eic/DATA/matilde-zucchini/actual/$DATETIME
#DIRNAME=/home/eic/DATA/matilde-zucchini/preparation/$DATETIME
mkdir -p $DIRNAME
cd $DIRNAME

echo " --- start the setup: /au/measure/readout-box/run-the-setup.sh $1 $STARTTIME"
echo "     running from: $DIRNAME "
nohup /au/measure/readout-box/run-the-setup.sh $1 $STARTTIME &> run-the-setup.log < /dev/null &

echo 
echo " --- TAKE NOTE OF THE DATE/TIME "
echo "     $DATETIME "

cd - &> /dev/null
