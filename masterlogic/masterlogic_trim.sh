#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ] || [ -x $3 ]; then
    echo "usage: $0 [masterlogic] [channel] [value]"
    exit 1
fi

timeout 30 /au/masterlogic/masterlogic_client.py --ml $1 --cmd "T $2 $3"
