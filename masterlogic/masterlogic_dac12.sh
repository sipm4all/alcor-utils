#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: masterlogic_dac12.sh [masterlogic]"
    exit 1
fi

#./masterlogic_client.py --ml $1 --cmd="R" | grep DAC12 | awk {'print $2, $3, $4'} 
while true; do
    timeout 2 $HOME/alcor/alcor-utils/masterlogic/masterlogic_client.py --ml $1 --cmd="R" | grep DAC12
    if [ $? == "124" ]; then
	echo " --- it timeout out, reset device "
	/au/masterlogic/reset $1
	sleep 3
	continue;
    fi
    break
done

