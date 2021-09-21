#!/bin/sh
here=`pwd`
cd ${ALCOR_DIR}/control
CONN=${ALCOR_ETC}/connection2.xml
DUMP_DIR=$2
declare mSipm=( [0]=FBK-2 [1]=HAMA1-2 [2]=FBK-1 [3]=HAMA2-2 [4]=BCOM-T1 [5]=BCOM-T2 )
declare mAlcor=( [0]=004 [1]=012 [2]=013 [3]=007 [4]=0T1 [5]=0T2 )


runNr=$1

# Init for all ALCOR inside detector box and 2 Timing Scint
for i in {0..5}; do
    sipm=${mSipm[$i]}
    alc=${mAlcor[$i]}
    conf=A$alc-$sipm
    echo "Dump ALCOR conf. for: $conf"
    conf=A$alc-$sipm-C$i
   ./alcorDump.py $CONN kc705 -c $i > $DUMP_DIR/$conf.alcordump
done | tee $DUMP_DIR/alcorDump.log

cd $here
