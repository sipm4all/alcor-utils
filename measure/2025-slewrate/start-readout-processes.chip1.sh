#! /usr/bin/env bash

staging=$(( 10 * 1024 * 1024 ))
occupancy=1024

### number of spills
nspill=100
if [ -n "$1" ]; then
    nspill=$1
fi
max_spill=10000

### ALCOR active lanes
chip0=$(( 0x1 ))
chip1=$(( 0xf ))
chip2=$(( 0x0 ))
chip3=$(( 0x0 ))
chip4=$(( 0x0 ))
chip5=$(( 0x0 ))

### trigger
trigg=0

### FPGA clock (must be in data)
clock=320

### mode selection 
bit_mode_run=0
bit_mode_spill_sw=1
bit_mode_spill_ext=2
bit_mode_tp_alcor_0=3
bit_mode_tp_alcor_1=4
bit_mode_tp_alcor_2=5
bit_mode_tp_alcor_3=6
bit_mode_tp_alcor_4=7
bit_mode_tp_alcor_5=8
bit_mode_tp_rev_pol=9

### filter
filter=$(( 0xf ))

### prepare output
runname=$(date +%Y%m%d-%H%M%S)
outputdir=/home/eic/DATA/2025-slewrate/actual/latest/subruns/$runname
mkdir -p $outputdir
mkdir -p $outputdir/cfg
mkdir -p $outputdir/log
mkdir -p $outputdir/raw
mkdir -p $outputdir/decoded
mkdir -p $outputdir/miniframe
ln -sfn $outputdir /home/eic/DATA/2025-slewrate/actual/latest/subruns/latest
echo $runname > /tmp/current.runname
echo $outputdir > /tmp/current.rundir

echo " --- new run started: $runname " | tee -a $outputdir/log/start-readout-processes.log
echo " --- running from: $outputdir " | tee -a $outputdir/log/start-readout-processes.log

### readout options
connection="/au/etc/connection.ch.8.xml"   
ctrl_readout_options="--connection $connection --usleep 1000 --filter $filter --nspill $max_spill"
nano_readout_options="--connection $connection --usleep 1000 --staging $staging --occupancy $occupancy --clock $clock --decode --output $outputdir/raw/alcdaq"
trig_readout_options="$nano_readout_options --trigger"
echo " --- ctrl-readout options: $ctrl_readout_options " | tee -a $outputdir/log/start-readout-processes.log
echo " --- nano-readout options: $nano_readout_options " | tee -a $outputdir/log/start-readout-processes.log

### build fifo bit map
fifo=$(( (chip0 << 0) + (chip1 << 4) + (chip2 << 8) + (chip3 << 12)  + (chip4 << 16)  + (chip5 << 20) ))

### start ctrl-readout process
/au/readout/bin/ctrl-readout $ctrl_readout_options &> $outputdir/log/ctrl-readout.log &
echo " --- started ctrl-readout process " | tee -a $outputdir/log/start-readout-processes.log
sleep 1

### start ALCOR nano-readout processes
for chip in {0..1}; do
    for lane in {0..3}; do	
       	bit=$(( 1 << ( lane + 4 * chip ) ))
	ififo=$(( lane + 4 * chip ))
	if [ $(( bit & fifo )) = 0 ]; then continue; fi
	/au/readout/bin/nano-readout $nano_readout_options --chip $chip --lane $lane &> $outputdir/log/nano-readout.chip$chip.lane$lane.log && \
	    /au/readout/bin/decoder --input $outputdir/raw/alcdaq.fifo_$ififo.dat --output $outputdir/decoded/alcdaq.fifo_$ififo.root &> $outputdir/log/decoder.chip$chip.lane$lane.log & # & \
#	    root -b -q -l "/home/eic/alcor/alcor-utils/measure/fastMiniFrame.C(\"$outputdir/decoded/alcdaq.fifo_$ififo.root\", \"$outputdir/miniframe/alcdaq.fifo_$ififo.miniframe.root\")" &> $outputdir/log/fastMiniFrame.chip$chip.lane$lane.log &
	echo " --- started nano-readout process: chip $chip, lane $lane " | tee -a $outputdir/log/start-readout-processes.log
    done
done

### start of run/spill
sleep 1
/au/readout/python/interprocess.py 0x09
sleep 1
for ispill in $(seq 1 $nspill); do
    echo " --- start of spill: ${ispill} / ${nspill}"
    /au/readout/python/interprocess.py 0x0b
    sleep 0.1
    echo " --- end of spill "
    /au/readout/python/interprocess.py 0x09
    sleep 0.1
    while [ -e "/tmp/.alcorInit" ]; do
	echo " --- wait alcorInit "
	sleep 1.0
    done
done
sleep 1
/au/readout/python/interprocess.py 0x0

### wait for processes to complete
echo " --- waiting for processes to complete " | tee -a $outputdir/log/start-readout-processes.log
wait
echo " --- done " | tee -a $outputdir/log/start-readout-processes.log

exit

### online data analysis
echo " --- start online data analysis " | tee -a $outputdir/log/start-readout-processes.log
hadd -f $outputdir/miniframe/alcdaq.miniframe.root $outputdir/miniframe/alcdaq.fifo_*.miniframe.root | tee -a $outputdir/log/start-readout-processes.log
root -b -q -l "/home/eic/alcor/alcor-utils/measure/readout-box/drawing_routines/scintillator_coincidence.C(\"$outputdir/miniframe/alcdaq.miniframe.root\")" | tee -a $outputdir/log/start-readout-processes.log

### send email
attachments=$(ls $outputdir/miniframe/*.png)
recipients="roberto.preghenella@bo.infn.it"
mail -r eicdesk01@bo.infn.it \
     -s "[Physics] $runname" \
     $(for i in $recipients; do echo "$i,"; done) \
     $(for i in $attachments; do echo "-A $i"; done) <<EOF
Sending from $outputdir.

(Do not reply, we won't read it)
EOF
