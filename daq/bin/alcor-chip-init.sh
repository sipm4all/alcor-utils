#! /usr/bin/env bash

if [ "$#" -ne 6 ]; then
    echo " usage: $0 [device] [chip] [lane] [eccr] [bcr] [pcr]"
    exit 1
fi
device=$1
chip=$2
lane=$3
eccr=$4
bcr=$5
pcr=$6

CONN="/etc/drich/drich_ipbus_connections.xml"
SWITCH="-s -i -m 0xffffffff -p 1"

LOG=/tmp/alcor-init.${device}.${chip}.log
echo Programming $chip
/au/control/alcorInit.py $CONN $device -c $chip -l $lane $SWITCH --eccr $eccr  --bcrfile /au/pdu/conf/bcr/$bcr.bcr --pcrfile /au/pdu/conf/pcr/$pcr.pcr | tee $LOG

### check end of configuration
if [[ $(tail -n 1 $LOG) == *"End of configuration"* ]]; then
    influx_data="alcor,device=$device,name=init,chip=$chip value=1"
else
    influx_data="alcor,device=$device,name=init,chip=$chip value=0"
fi
influx_write.sh "${influx_data}"
sleep 0.1

### check alignment
for thelane in {0..3}; do
    
    influx_data="alcor,device=$device,name=align8,chip=$chip,lane=$thelane value=0"
    influx_write.sh "${influx_data}"
    influx_data="alcor,device=$device,name=align32,chip=$chip,lane=$thelane value=0"
    influx_write.sh "${influx_data}"

    match=$(awk -v lane="$thelane" '$1 == "Lane" && $4 == lane {print $6, $8}' $LOG)
    [ ! -n "$match" ] && continue
    read align8 align32 <<< $match
    [[ "$align8" == "OK" ]] && align8=1 || align8=0
    [[ "$align32" == "OK" ]] && align32=1 || align32=0

    influx_data="alcor,device=$device,name=align8,chip=$chip,lane=$thelane value=$align8"
    influx_write.sh "${influx_data}"
    influx_data="alcor,device=$device,name=align32,chip=$chip,lane=$thelane value=$align32"
    influx_write.sh "${influx_data}"
done
