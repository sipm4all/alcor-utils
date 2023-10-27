#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 [name]"
    exit 1
fi
name=$1

devices=$(awk '$1 !~ /^#/' /etc/drich/drich_readout.conf | awk {'print $4'} | sort | uniq | tr '\n' ' ')
for device in $devices; do
    [[ $name != "all" ]] && [[ $name != $device ]] && continue
    echo " --- alcorInit on $device "
    /au/pdu/control/alcorInit.sh ${device} 666 /tmp &> /tmp/alcorInit.${device}.log && grep "FAILED" /tmp/alcorInit.${device}.log &> /dev/null && echo " --- alcorInit on $device FAILED " || echo " --- alcorInit on $device OK " && grep "RETRY" /tmp/alcorInit.${device}.log &> /dev/null && echo " --- alcorInit on $device WARNING " 
done
wait

exit

while read -r name ip target firmware monitor enabled; do
    [[ $name =~ ^#.* ]] && continue
done < /etc/drich/drich_kc705.conf

echo " --- wait for init to be completed "
wait
sleep 3

exit


### check
while read -r id target enabled; do
    if [ $id == "#" ]; then
	continue
    fi

    chip=0
    for ena in $enabled; do

	for ((lane = 0; lane < 4; lane++)); do
	    bit=$(($ena >> i & 1))
	    if [ "$bit" -eq 1 ]; then
		echo -n " --- alcor_check on KC705 #${id} chip ${chip} lane ${lane}: "
		/au/pdu/measure/alcor_check.sh ${id} ${chip} ${lane} &> /var/pdu/log/alcor_check.${id}.${chip}.${lane}.log && echo " SUCCESS " || " FAIL "
	    fi
	done
	chip=$(($chip + 1))
    done
done < $conf


