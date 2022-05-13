#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: masterlogic_dac12.sh [masterlogic]"
    exit 1
fi

#./masterlogic_client.py --ml $1 --cmd="R" | grep DAC12 | awk {'print $2, $3, $4'} 
$HOME/alcor/alcor-utils/masterlogic/masterlogic_client.py --ml $1 --cmd="R" | grep DAC12
