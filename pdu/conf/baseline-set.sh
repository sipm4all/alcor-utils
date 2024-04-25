#! /usr/bin/env bash

### external parameters
if [ "$#" -ne 2 ]; then
    echo " usage: $0 [device] [baseline-run] "
    exit 1
fi
_device=$1
baseline=$2

while read -r device ip target firmware monitor enabled; do
    [[ $device =~ ^#.* ]] && continue
    [[ $_device -ne "all" ]] && [[ $_device -ne $device ]] && continue

    echo
    
    if [[ $device == "kc705-207" ]]; then
	echo " kc705-207 config init is inhibited, good day "
	continue
    fi

    ### check baseline calibration run exists
    if [ ! -d /au/pdu/conf/pcr/baseline-calibration/${device}/${baseline} ]; then
	echo " baseline calibration run ${baseline} does not exist for device ${_device} "
	continue
    fi
    
    ### obtain enabled chips from configuration
    chips=$(awk -v device="$device" '$1 !~ /^#/ && $4 == device' /etc/drich/drich_readout.conf | awk {'print $5, $6'} | tr '\n' ' ')
    ENA=("0x0" "0x0" "0x0" "0x0" "0x0" "0x0")
    for chip in $chips; do
	[[ ! $chip =~ ^[0-5]$ ]] && continue
	ENA[$chip]="0xf"
    done

    ### create current from delta10
    for chip in {0..5}; do
	cp /au/pdu/conf/pcr/baseline-calibration/${device}/${baseline}/PCR/chip${chip}.range2.delta10.pcr /au/pdu/conf/pcr/baseline-calibration/${device}/${baseline}/PCR/chip${chip}.range2.current.pcr
    done
    
    cat <<EOF > /au/pdu/conf/readout.${device}.current.conf
# chip  mask	eccr	bcr		pcr
0 	${ENA[0]}	0xb01b	current	baseline-calibration/${device}/${baseline}/PCR/chip0.range2.current
1 	${ENA[1]}	0xb01b	current	baseline-calibration/${device}/${baseline}/PCR/chip1.range2.current
2 	${ENA[2]}	0xb01b	current	baseline-calibration/${device}/${baseline}/PCR/chip2.range2.current
3 	${ENA[3]}	0xb01b	current	baseline-calibration/${device}/${baseline}/PCR/chip3.range2.current
4 	${ENA[4]}	0xb01b	current	baseline-calibration/${device}/${baseline}/PCR/chip4.range2.current
5 	${ENA[5]}	0xb01b	current	baseline-calibration/${device}/${baseline}/PCR/chip5.range2.current
# don't delete this line
EOF
    
    ln -sf /home/eic/DATA/2024-testbeam/actual/baseline-scan/${device}/${baseline}/readout.${device}.baseline.conf /au/pdu/conf/readout.${device}.baseline.conf 
    ln -sf /au/pdu/conf/readout.${device}.current.conf /au/pdu/conf/readout.${device}.conf

    echo " --- configuration for device ${device} updated "
    cat /au/pdu/conf/readout.${device}.conf

done < /etc/drich/drich_kc705.conf
