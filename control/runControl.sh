#!/bin/sh
source ~/.bashrc
here=`pwd`
####
# Here parameters for configuration

####
INIT_DIR=${ALCOR_DIR}/control
runNumber=`cat $INIT_DIR/rnbr.dat`
runNumber=$(($runNumber+1))
echo $runNumber > $INIT_DIR/rnbr.dat
now=`date +%Y%m%d%H%M%S`
echo "------- dRICH Run: $runNumber"
rNo=$(printf %05d $runNumber)
OUT_DIR=${DRICH_OUT}/$rNo.$now
echo Output Directory: $OUT_DIR
mkdir $OUT_DIR

### -- dump HV settings
./hvdump.sh | tee $OUT_DIR/HV.dump
### -- dump TEMP status
./tempstatus.sh | tee $OUT_DIR/TEMP.dump 

read -p " Check temperatures! And then press any key to continue or ctrl-c to exit " -n 1 -r


### -- init all ALCOR
${ALCOR_DIR}/control/alcorInit.sh $runNumber $OUT_DIR

### special settings to survive  [work in progress]
#echo " --- loading special settings to survive"
#./channelMap.sh 

### -- dump all ALCOR config   --- this must be the last one before to start
#${ALCOR_DIR}/control/alcorDump.sh $runNumber $OUT_DIR

### -- start readout:
read -p " do you really want to start the run ? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    ${ALCOR_DIR}/control/startReadout.sh $runNumber $OUT_DIR
else
    cd $here
    exit 0
fi

echo "End of Run: $runNumber Data Stored in : $OUT_DIR"

### -- start decode:
read -p " do you want to decode the data ? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    ${ALCOR_DIR}/control/startDecode.sh $OUT_DIR
fi

### -- start decode:
read -p " do you want to produce QA plots ? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    ${ALCOR_DIR}/control/startQA.sh $OUT_DIR
    display $OUT_DIR/plotChip.png
fi

cd $here
