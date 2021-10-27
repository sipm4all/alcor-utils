#!/bin/sh
here=`pwd`
cd ${ALCOR_DIR}/hvsetup
for i in {0..4}; do
echo "HV Settings carrier $i "
./dacs.py  ML$i | grep DAC12 
done
cd $here

