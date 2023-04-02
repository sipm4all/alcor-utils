#! /usr/bin/env bash

### REPROGRAM FPGA
#/home/eic/alcor/alcor-utils/firmware/program.sh dev $KC705_TARGET true
#sleep 5

ln -sf /au/conf/readout.scan.conf /au/conf/readout.conf

THRS=$(seq 0 30)
#THRS="15 40"

for thr in $THRS; do
    
    for chip in {0..0}; do
	bcrfile=$(grep "^$chip" /au/conf/readout.baseline.conf | awk {'print $4'})
	cp /au/conf/bcr/$bcrfile.bcr /au/conf/bcr/chip$chip.bcr
	pcrfile=$(grep "^$chip" /au/conf/readout.baseline.conf | awk {'print $5'})
	/au/readout/python/updatePCR.py --filein /au/conf/pcr/$pcrfile.pcr --delta_threshold $thr > /au/conf/pcr/chip$chip.pcr
    done

    /au/readout/scripts/start-readout-processes.sh &
    wait

    dir=$(cat /tmp/current.rundir)
    mv $dir $dir-threshold-scan-$thr
    
done

ln -sf /au/conf/readout.run.conf /au/conf/readout.conf
