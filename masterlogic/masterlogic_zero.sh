#! /usr/bin/env bash

if [ -x $1 ] ; then
    echo "usage: $0 [masterlogic]"
    exit 1
fi

ML=$1
VALUE=0

### even channel
for DAC in 0 1 2 3 4 5 6 7; do
    $HOME/alcor/alcor-utils/masterlogic/masterlogic_client.py --ml $ML --cmd="D $DAC $VALUE " &> /dev/null
done

### read back
$HOME/alcor/alcor-utils/masterlogic/masterlogic_dac12.sh $1
