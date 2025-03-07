#! /usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo " usage: $0 [device] [delta-threshold] [opmode] "
    exit 1 
fi
_device=$1
delta_threshold=$2
opmode=$3

while read -r device ip target firmware monitor enabled; do
    [[ $device =~ ^#.* ]] && continue
    [[ $_device -ne "all" ]] && [[ $_device -ne $device ]] && continue

    echo " --- updating PCR for device ${device} "
    for filein in $(grep baseline-calibration /au/pdu/conf/readout.${device}.baseline.conf | awk {'print $5'}); do

	echo /au/pdu/conf/pcr/${filein}.pcr /au/pdu/conf/pcr/${filein}.current.pcr
	if [[ $device == "kc705-207" ]]; then
	    /au/readout/python/updatePCR.py --filein /au/pdu/conf/pcr/${filein}.pcr --opmode ${opmode} --delta_threshold 25 > /au/pdu/conf/pcr/${filein}.current.pcr
	else
	    /au/readout/python/updatePCR.py --filein /au/pdu/conf/pcr/${filein}.pcr --opmode ${opmode} --delta_threshold ${delta_threshold} > /au/pdu/conf/pcr/${filein}.current.pcr
	fi
	
    done

done < /etc/drich/drich_kc705.conf

