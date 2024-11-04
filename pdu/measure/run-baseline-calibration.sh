#! /usr/bin/env bash

### default arguments
BCRCONF="current"
ENA=("0x0" "0x0" "0x0" "0x0" "0x0" "0x0")
#RANGE=("0" "0" "0" "0" "0" "0")
RANGE=("1" "1" "1" "1" "1" "1")
RANGE=("2" "2" "2" "2" "2" "2")
DELTA=("5" "5" "5" "5" "5" "5")
DELTA=("15" "15" "15" "15" "15" "15")

### external parameters
if [ "$#" -ne 2 ]; then
    echo " usage: $0 [run-name] [device] "
    exit 1
fi
runname=$1
DEVICE=$2

### prevent running on kc205-200 timing
if [[ $DEVICE == "kc705-200" ]]; then
    echo " --- kc705-200 baseline calibration is inhibited, good day "
    exit 0
fi

### check we are not running already
[ -f /tmp/run-baseline-calibration.$DEVICE.running ] && exit 1

### obtain enabled chips from configuration
chips=$(awk -v device="$DEVICE" '$1 !~ /^#/ && $4 == device' ${AU_READOUT_CONFIG} | awk {'print $5, $6'} | tr '\n' ' ')
for chip in $chips; do
    [[ ! $chip =~ ^[0-5]$ ]] && continue
    ENA[$chip]="0xf"
done

### check BCR configuration exists
if [ ! -f "/au/pdu/conf/bcr/$BCRCONF.bcr" ]; then
    echo " --- unknown BCR configuration: $BCRCONF " 
    exit 1
fi

BASEDIR=$HOME/DATA/2024-testbeam/actual/baseline-scan/${DEVICE}
DIR=$BASEDIR/${runname}

echo " ---"
echo " --- starting baseline calibration: $DIR "
echo " --- running with BCR configuration: $BCRCONF "
echo " --- enable configuration: ${ENA[@]} "
echo " ---"

### notify database 
influx_write.sh "kc705,device=${DEVICE},name=baseline-calibration value=1"
telegram_message.sh "started baseline calibration: ${DEVICE}"
touch /tmp/run-baseline-calibration.$DEVICE.running

### create output directory
mkdir -p $DIR
ln -sfn $DIR $BASEDIR/latest

### obtain masterlogic boards from configuration and set to zero
#masterlogics=$(awk -v device="$DEVICE" '$1 !~ /^#/ && $4 == device' ${AU_READOUT_CONFIG} | awk {'print $7'} | tr '\n' ' ')
#for masterlogic in $masterlogics; do
#    /au/pdu/masterlogic/zero $masterlogic
#done
#sleep 1

### prepare to run bolognaScan
cat <<EOF > $DIR/readout.${DEVICE}.maxthreshold.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 ${ENA[0]}	 0xb01b         ${BCRCONF}	maxthreshold
1	 ${ENA[1]}	 0xb01b 	${BCRCONF}	maxthreshold
2  	 ${ENA[2]}	 0xb01b 	${BCRCONF}	maxthreshold
3  	 ${ENA[3]}	 0xb01b 	${BCRCONF}	maxthreshold
4  	 ${ENA[4]}	 0xb01b 	${BCRCONF}	maxthreshold
5  	 ${ENA[5]}	 0xb01b 	${BCRCONF}	maxthreshold
# don't delete this line
EOF
ln -sf $DIR/readout.${DEVICE}.maxthreshold.conf /au/pdu/conf/readout.${DEVICE}.conf

### bolognaScan
/au/pdu/measure/bolognaScan.sh ${DEVICE} ${DIR} | tee $DIR/bolognaScan.log

### link PCR files
mkdir -p /au/pdu/conf/pcr/baseline-calibration/${DEVICE}
ln -sf $DIR /au/pdu/conf/pcr/baseline-calibration/${DEVICE}/.
PCRDIR="baseline-calibration/${DEVICE}/${runname}/PCR"

### create baseline readout.conf
cat <<EOF > $DIR/readout.${DEVICE}.baseline.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 ${ENA[0]}	 0xb01b 	${BCRCONF}	${PCRDIR}/chip0.range${RANGE[0]}
1	 ${ENA[1]}	 0xb01b         ${BCRCONF}	${PCRDIR}/chip1.range${RANGE[1]}
2  	 ${ENA[2]}	 0xb01b 	${BCRCONF}	${PCRDIR}/chip2.range${RANGE[2]}
3  	 ${ENA[3]}	 0xb01b 	${BCRCONF}	${PCRDIR}/chip3.range${RANGE[3]}
4  	 ${ENA[4]}	 0xb01b 	${BCRCONF}	${PCRDIR}/chip4.range${RANGE[4]}
5  	 ${ENA[5]}	 0xb01b 	${BCRCONF}	${PCRDIR}/chip5.range${RANGE[5]}
# don't delete this line
EOF
ln -sf $DIR/readout.${DEVICE}.baseline.conf /au/pdu/conf/readout.${DEVICE}.baseline.conf

### create run readout.conf
cat <<EOF > $DIR/readout.${DEVICE}.current.conf
# chip	 laneMask=0/0xF	 eccr		conf/bcr	conf/pcr
0 	 ${ENA[0]}	 0xb01b 	${BCRCONF}	${PCRDIR}/chip0.range${RANGE[0]}.current
1	 ${ENA[1]}	 0xb01b         ${BCRCONF}	${PCRDIR}/chip1.range${RANGE[1]}.current
2  	 ${ENA[2]}	 0xb01b 	${BCRCONF}	${PCRDIR}/chip2.range${RANGE[2]}.current
3  	 ${ENA[3]}	 0xb01b 	${BCRCONF}	${PCRDIR}/chip3.range${RANGE[3]}.current
4  	 ${ENA[4]}	 0xb01b 	${BCRCONF}	${PCRDIR}/chip4.range${RANGE[4]}.current
5  	 ${ENA[5]}	 0xb01b 	${BCRCONF}	${PCRDIR}/chip5.range${RANGE[5]}.current
# don't delete this line
EOF
ln -sf $DIR/readout.${DEVICE}.current.conf /au/pdu/conf/readout.${DEVICE}.current.conf

### link main readout.conf
ln -sf /au/pdu/conf/readout.${DEVICE}.current.conf /au/pdu/conf/readout.${DEVICE}.conf

### bolognaScan
/au/pdu/measure/bolognaScan.sh ${DEVICE} ${DIR} final true | tee $DIR/bolognaScan.final.log
/au/readout/scripts/draw_allchannel.sh $DIR final

echo " ---"
echo " --- baseline calibration completed "
echo " ---"

### update webpage
/au/pdu/measure/create-baseline-webpage.sh latest

### notify database 
influx_write.sh "kc705,device=${DEVICE},name=baseline-calibration value=0"
telegram_message.sh "baseline calibration completed: ${DEVICE}"
rm /tmp/run-baseline-calibration.$DEVICE.running

