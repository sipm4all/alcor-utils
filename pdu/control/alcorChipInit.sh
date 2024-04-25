#! /usr/bin/env bash

if [ $# -ne 2 ]; then
    echo " usage: $0 [device] [chip]"
    exit 1
fi
device=$1
_chip=$2
if [ "$4" = "true" ]; then
    THRSCAN=true
fi

RDOUT_CONF="/au/pdu/conf/readout.${_device}.conf"
CONN="/etc/drich/drich_ipbus_connections.xml"
SWITCH="-s -i -m 0xffffffff -p 1"

if [ $runNr -eq 0 ]; then
 SWITCH="-s -i -m 0x0 -p 1"
fi

while read -r chip lane eccr bcr pcr
do
 if [ $chip != "#" ]; then
# echo $chip $lane $eccr $bcr $pcr
   ldec=$(printf "%d" $lane)
   if [ $ldec -ne 0 ]; then
       echo Programming $chip
#       /au/pdu/measure/the_sequence.sh $device $chip
       /au/control/alcorInit.py $CONN $device -c $chip -l $lane $SWITCH --eccr $eccr  --bcrfile /au/pdu/conf/bcr/$bcr.bcr --pcrfile /au/pdu/conf/pcr/$pcr.pcr | tee >(grep "End of configuration" &> /dev/null && echo " >>> INIT CHIP $chip OK " || echo " >>> FAILED TO INIT CHIP $chip ") & 
       fi
   fi
 fi
done < $RDOUT_CONF

wait
sleep 0.1

#cd $here
