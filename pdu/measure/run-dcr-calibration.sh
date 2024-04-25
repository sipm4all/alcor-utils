#! /usr/bin/env bash

### external parameters
if [ "$#" -ne 2 ]; then
    echo " usage: $0 [run-name] [device] "
    exit 1
fi
runname=$1
DEVICE=$2

### check we are not running already
[ -f /tmp/run-baseline-calibration.$DEVICE.running ] && exit 1

BASEDIR=$HOME/DATA/2024-testbeam/actual/baseline-scan/${DEVICE}
DIR=$BASEDIR/${runname}

echo " ---"
echo " --- starting dcr calibration: $DIR "
echo " ---"

### notify database 
influx_write.sh "kc705,device=${DEVICE},name=dcr-scan value=1"
telegram_message.sh "started DCR scan: ${DEVICE}"
touch /tmp/run-dcr-calibration.$DEVICE.running

### create output directory
mkdir -p $DIR
ln -sfn $DIR $BASEDIR/latest

### bolognaScan
/au/pdu/measure/bolognaScan.sh ${DEVICE} ${DIR} final true | tee $DIR/bolognaScan.final.log
/au/readout/scripts/draw_allchannel.sh $DIR final

echo " ---"
echo " --- dcr calibration completed "
echo " ---"

### update webpage
#/au/pdu/measure/create-baseline-webpage.sh

### notify database 
influx_write.sh "kc705,device=${DEVICE},name=dcr-scan value=0"
telegram_message.sh "DCR sca completed: ${DEVICE}"
rm /tmp/run-baseline-calibration.$DEVICE.running

