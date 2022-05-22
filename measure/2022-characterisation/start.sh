#! /usr/bin/env bash

if [ -z $1 ] || [ -z $2 ]; then
    echo "usage: $0 [NEW/IRR/ANN] [STEP]"
    exit 1
fi


### check token
if [ -f "/tmp/run-the-setup.running" ]; then
    echo " --- there is already a running THE setup"
    exit 1
fi

DATETIME=$(date +%Y%m%d-%H%M%S)

DIRNAME=/home/eic/DATA/2022-characterisation/actual/$DATETIME
mkdir -p $DIRNAME
cd $DIRNAME

echo " --- start the setup: /au/measure/2022-characterisation/run-the-setup.sh $1 $2 "
echo "     running from: $DIRNAME "
nohup /au/measure/2022-characterisation/run-the-setup.sh $1 $2 &> run-the-setup.log < /dev/null &

echo 
echo " --- TAKE NOTE OF THE DATE/TIME "
echo "     $DATETIME "

cd - &> /dev/null
