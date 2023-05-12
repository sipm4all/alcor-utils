#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ] || [ -x $3 ]; then
    echo "usage: masterlogic_set.sh [masterlogic] [dac] [value]"
    exit 1
fi

ML=$1
DAC=$2
VALUE=$3

while true; do
    timeout 30 $HOME/alcor/alcor-utils/masterlogic/masterlogic_client.py --ml $ML --cmd="D $DAC $VALUE " &> /dev/null
    if [ $? == "124" ]; then
	echo " --- it timeout out, reset device "
	/au/masterlogic/reset $1
	sleep 3
	continue;
    fi
    break
done
#$HOME/alcor/alcor-utils/masterlogic/masterlogic_dac12.sh $1
