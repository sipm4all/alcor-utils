#!/bin/sh

here=`pwd`
cd ${ALCOR_DIR}/hvsetup
for i in {0..3}; do
tt=`./lm73.py  ML$i | awk '{print $3}'`
echo "Status temp $i: $tt"
done
cd $here


#today=`date +%Y-%m-%d`
#SSHC="ssh -p 2200 tb@192.168.0.5"
#echo "Status Peltier 2"
#$SSHC "tail -n 1 /data/nfs/raspi/data/Peltier/peltier-2_$today.txt"
#echo "Status Peltier 3"
#$SSHC "tail -n 1 /data/nfs/raspi/data/Peltier/peltier-3_$today.txt"
