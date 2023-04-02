#! /usr/bin/env bash

### REPROGRAM FPGA
#/home/eic/alcor/alcor-utils/firmware/program.sh dev $KC705_TARGET true
#sleep 5

ln -sf /au/conf/readout.scan.conf /au/conf/readout.conf

chip="0"
range="0"
offset="6"
threshold="30"
xychannel="A1"
eochannel=$(/au/readout/python/mapping.py --xy2eo $xychannel)

bcrfile=$(grep "^$chip" /au/conf/readout.baseline.conf | awk {'print $4'})
cp /au/conf/bcr/$bcrfile.bcr /au/conf/bcr/chip$chip.bcr
pcrfile=$(grep "^$chip" /au/conf/readout.baseline.conf | awk {'print $5'})
/au/readout/python/updatePCR.py --filein /au/conf/pcr/$pcrfile.pcr \
				--offset $offset \
				--range $range \
				--threshold $threshold \
				--one_channel $eochannel \
				> /au/conf/pcr/chip$chip.pcr

/au/readout/scripts/start-readout-processes.sh &
wait

dir=$(cat /tmp/current.rundir)
mv $dir $dir-onescan
    

ln -sf /au/conf/readout.run.conf /au/conf/readout.conf
