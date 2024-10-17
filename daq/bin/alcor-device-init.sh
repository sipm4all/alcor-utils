#! /usr/bin/env bash

if [ -z $1 ]; then
    echo " usage: $0 [device] [chip]"
    exit 1
fi
device=$1
_chip=$2

RDOUT_CONF="/au/pdu/conf/readout.${device}.conf"
CONN="${AU_IPBUS_CONNECTIONS}"
SWITCH="-s -i -m 0xffffffff -p 1"

while read -r chip lane eccr bcr pcr; do
    [[ $chip =~ ^#.* ]] && continue
    [[ $_chip != "all" ]] && [[ $_chip != $chip ]] && continue
    ldec=$(printf "%d" $lane)
    [ $ldec -eq 0 ] && continue
#    /home/eic/bin/alcor-chip-init.sh $device $chip $lane $eccr $bcr $pcr &
    /home/eic/bin/alcor-chip-init.sh $device $chip $lane $eccr $bcr $pcr ### slower, do it in series
done < $RDOUT_CONF
wait
sleep 0.1

### frequency test
while read -r chip lane eccr bcr pcr; do
    [[ $chip =~ ^#.* ]] && continue
    [[ $_chip != "all" ]] && [[ $_chip != $chip ]] && continue
    ldec=$(printf "%d" $lane)
    [ $ldec -eq 0 ] && continue
    for thelane in {0..3}; do
	/au/pdu/measure/alcor-frequency-test.sh $device $chip $thelane 0.1
    done
done < $RDOUT_CONF
