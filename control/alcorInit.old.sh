#!/bin/sh
here=`pwd`
cd ${ALCOR_DIR}/control
pwd
BCR_DIR=${ALCOR_CONF}/bcr
PCR_DIR=${ALCOR_CONF}/pcr
RDOUT_CONF=${ALCOR_CONF}/readout.conf
CONN=${ALCOR_ETC}/connection2.xml
runNr=$1
DUMP_DIR=$2
THRSCAN=false
if [ "$3" = "true" ]; then
    THRSCAN=true
fi
if [ -z "$4" ]; then
delay=11
else
delay=$4
fi 


SWITCH="-s -i -m 0xffffffff -p 1"

if [ $runNr -eq 0 ]; then
 echo "Run Number 0"
 DUMP_LOG=/dev/null
 SWITCH="-s -i -m 0x0 -p 1"
else
 echo "Run Number not zero"
 DUMP_LOG=$DUMP_DIR/alcorInit.log
 cp $RDOUT_CONF $DUMP_DIR
fi

while read -r chip lane eccr bcr pcr
do
 if [ $chip != "#" ]; then
# echo $chip $lane $eccr $bcr $pcr
   ldec=$(printf "%d" $lane)
   if [ $ldec -ne 0 ]; then
       echo Programming $chip
       if [ "$THRSCAN" = true ]; then
	   ${ALCOR_DIR}/control/alcorInit.py $CONN kc705 -c $chip -l $lane  -d $delay $SWITCH --eccr 0xb81b --bcrfile ${BCR_DIR}/$bcr.bcr --pcrfile ${PCR_DIR}/$pcr.pcr & 
       else
	   ${ALCOR_DIR}/control/alcorInit.py $CONN kc705 -c $chip -l $lane  -d $delay $SWITCH --eccr $eccr --bcrfile ${BCR_DIR}/$bcr.bcr --pcrfile ${PCR_DIR}/$pcr.pcr &
       fi
       if [ $runNr -ne 0 ]; then
	   cp ${BCR_DIR}/$bcr.bcr $DUMP_DIR/chip$chip.bcr
	   cp ${PCR_DIR}/$pcr.pcr $DUMP_DIR/chip$chip.pcr
       fi
   fi
 fi
done < $RDOUT_CONF | tee $DUMP_LOG

#if [ "$THRSCAN" = true ]; then
#    wait
#fi
wait
sleep 0.1

cd $here
