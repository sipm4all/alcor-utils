#! /usr/bin/env bash

known_setups=("memmert-hama3")

if [ -z $1 ]; then
    echo " usage: $0 [setup] "
    echo " known setups: ${known_setups[@]}"
    exit 1
fi

if [[ ! "${known_setups[@]}" =~ "${1}" ]]; then
    echo " unknown setup: $1 "
    echo " usage: $0 [setup] "
    echo " known setups: ${known_setups[@]} "
    exit 1
fi

### check token
if [ -f "/tmp/run-the-setup.running" ]; then
    echo " --- there is already a running THE setup: $(cat /tmp/run-the-setup.running)"
    exit 1
fi

DATETIME=$(date +%Y%m%d-%H%M%S)

DIRNAME=/home/eic/DATA/2023-characterisation/actual/$DATETIME
mkdir -p $DIRNAME
cd $DIRNAME

echo " --- start the setup: /au/measure/2023-characterisation/run-the-setup.sh $1 "
echo "     running from: $DIRNAME "
nohup /au/measure/2023-characterisation/run-the-setup.sh $1 &> run-the-setup.log < /dev/null &

echo 
echo " --- TAKE NOTE OF THE DATE/TIME "
echo "     $DATETIME "

cd - &> /dev/null
