#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: masterlogic_dac12.sh [masterlogic]"
    exit 1
fi

/au/masterlogic/masterlogic_client.py --ml $1 --cmd="R" | grep DAC8
