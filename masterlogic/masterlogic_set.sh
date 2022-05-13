#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: masterlogic_set.sh [masterlogic] [value] [value2]"
    exit 1
fi

ML=$1
VALUE=$2
VALUE2=$VALUE
if [ ! -x $3 ]; then
    VALUE2=$3
fi

### even channel
for DAC in 0 2 4 6; do
    $HOME/alcor/alcor-utils/masterlogic/masterlogic_client.py --ml $ML --cmd="D $DAC $VALUE " &> /dev/null
done

### odd channels
for DAC in 1 3 5 7; do
    $HOME/alcor/alcor-utils/masterlogic/masterlogic_client.py --ml $ML --cmd="D $DAC $VALUE2 " &> /dev/null
done

### read back
$HOME/alcor/alcor-utils/masterlogic/masterlogic_dac12.sh $1
