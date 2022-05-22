#! /usr/bin/env bash

SLEEPS="0.5"
DEVICE=$1

stty speed 115200 -F $DEVICE
echo " --- setting HV on $DEVICE from $2"
read -p " are you sure? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then

    echo -e "P \n\r" > $DEVICE
    sleep $SLEEPS
    cat $2 | while read line; do
	echo $line
	echo -e "$line \r" > $DEVICE
	sleep $SLEEPS; 
    done

fi

### read back DAC values
echo " --- $DEVICE reading "
(cat $DEVICE | grep DAC12) &
pid=$!
echo -e "R \n\r" > $DEVICE && sleep $SLEEPS
killall cat
echo
