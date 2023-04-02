#! /usr/bin/env bash

if [ -x $1 ] ; then
    echo "usage: $0 [masterlogic]"
    exit 1
fi

ML=$1
VALUE=0

### even channel
for DAC in 0 1 2 3 4 5 6 7; do

    while true; do
	timeout 2 $HOME/alcor/alcor-utils/masterlogic/masterlogic_client.py --ml $ML --cmd="D $DAC $VALUE " &> /dev/null
	if [ $? == "124" ]; then
	    echo " --- it timeout out, reset device "
	    /au/masterlogic/reset $1
	    sleep 3
	    continue;
	fi
	break
    done

done

timeout 2 $HOME/alcor/alcor-utils/masterlogic/masterlogic_client.py --ml $ML --cmd="Z 1 " &> /dev/null

### read back
$HOME/alcor/alcor-utils/masterlogic/masterlogic_dac12.sh $1
