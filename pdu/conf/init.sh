#! /usr/bin/env bash

### default arguments
BCRCONF="standard"
PCRCONF="maxthreshold"

### ALCOR test arguments
#BCRCONF="off"
#PCRCONF="off"

### external parameters
if [ "$#" -ne 1 ]; then
    echo " usage: $0 [device] "
    exit 1
fi
_device=$1

while read -r device ip target firmware monitor enabled; do
    [[ $device =~ ^#.* ]] && continue
    [[ $_device -ne "all" ]] && [[ $_device -ne $device ]] && continue

    echo
    
    if [[ $device == "kc705-200" ]]; then
	echo " kc705-200 config init is inhibited, good day "
	continue
    fi

    ### obtain enabled chips from configuration
    chips=$(awk -v device="$device" '$1 !~ /^#/ && $4 == device' /etc/drich/drich_readout.conf | awk {'print $5, $6'} | tr '\n' ' ')
    ENA=("0x0" "0x0" "0x0" "0x0" "0x0" "0x0")
    for chip in $chips; do
	[[ ! $chip =~ ^[0-5]$ ]] && continue
	ENA[$chip]="0xf"
    done

    cat <<EOF > /au/pdu/conf/readout.${device}.init.conf
# chip  mask	eccr	bcr		pcr
0 	${ENA[0]}	0xb01b	${BCRCONF}	${PCRCONF}
1 	${ENA[1]}	0xb01b	${BCRCONF}	${PCRCONF}
2 	${ENA[2]}	0xb01b	${BCRCONF}	${PCRCONF}
3 	${ENA[3]}	0xb01b	${BCRCONF}	${PCRCONF}
4 	${ENA[4]}	0xb01b	${BCRCONF}	${PCRCONF}
5 	${ENA[5]}	0xb01b	${BCRCONF}	${PCRCONF}
# don't delete this line
EOF
    
    ln -sf /au/pdu/conf/readout.${device}.init.conf /au/pdu/conf/readout.${device}.conf

    echo " --- configuration for device ${device} initialised "
    cat /au/pdu/conf/readout.${device}.conf

done < /etc/drich/drich_kc705.conf
