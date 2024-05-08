#! /usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo " usage: $0 [run-name] [device] "
    exit 1
fi
runname=$1
device=$2

### staging buffer and download occupancy parameters
staging=$(( 32 * 1024 * 1024 ))
occupancy=1024
occupancy=256
occupancy=8
[[ -v DRICH_READOUT_OCCUPANCY ]] && occupancy=$DRICH_READOUT_OCCUPANCY

### stop after number of spills (big number here)
nspill=1
[[ -v DRICH_READOUT_NSPILL ]] && nspill=$DRICH_READOUT_NSPILL

### obtain enabled chips from configuration
ENA=("0x0" "0x0" "0x0" "0x0" "0x0" "0x0")
chips=$(awk -v device="$device" '$1 !~ /^#/ && $4 == device' /etc/drich/drich_readout.conf | awk {'print $5, $6'} | tr '\n' ' ')
for chip in $chips; do
    [[ ! $chip =~ ^[0-5]$ ]] && continue
    ENA[$chip]="0xf"
done

### trigger
trigg=0
awk -v device="$device" '$2 == device && !/^#/' /etc/drich/drich_trigger.conf && trigg=1

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
[[ -v DRICH_READOUT_FILTER ]] && filter=$DRICH_READOUT_FILTER
#filter=$(( 0x1 )) # R+TEST

### prepare output
outputdir=/home/eic/DATA/2024-testbeam/actual/physics/$runname/$device
mkdir -p $outputdir
mkdir -p $outputdir/cfg
mkdir -p $outputdir/log
mkdir -p $outputdir/raw
mkdir -p $outputdir/decoded
mkdir -p $outputdir/miniframe
mkdir -p $outputdir/dcr
#echo $runname > /tmp/current.runname
#echo $outputdir > /tmp/current.rundir

echo " --- new run started: $runname " | tee -a $outputdir/log/start-readout-processes.log
echo " --- launch processes for device: $device " | tee -a $outputdir/log/start-readout-processes.log
echo " --- running from: $outputdir " | tee -a $outputdir/log/start-readout-processes.log

### copy relevant configuration files
cp -L $0 $outputdir/cfg/$(basename "$0")
cp -L /au/pdu/conf/readout.$device.conf $outputdir/cfg/readout.conf
for chip in {0..5}; do
    bcrfile=$(grep "^$chip" /au/pdu/conf/readout.$device.conf | awk {'print $4'})
    cp /au/pdu/conf/bcr/$bcrfile.bcr $outputdir/cfg/chip$chip.bcr
    pcrfile=$(grep "^$chip" /au/pdu/conf/readout.$device.conf | awk {'print $5'})
    cp /au/pdu/conf/pcr/$pcrfile.pcr $outputdir/cfg/chip$chip.pcr
done

### save masterlogic values
#for I in {0..0}; do /au/masterlogic/dac12 $I &> $outputdir/cfg/masterlogic.$I.dac12 & done; wait
#for I in {0..0}; do /au/masterlogic/dac8  $I &> $outputdir/cfg/masterlogic.$I.dac8  & done; wait
#for I in {0..0}; do /au/masterlogic/temp  $I &> $outputdir/cfg/masterlogic.$I.temp  & done; wait

### readout options
connection="/etc/drich/drich_ipbus_connections.xml"
ctrl_readout_options="--connection $connection --device $device --usleep 100 --filter $filter --nspill $nspill"
#nano_readout_options="--connection $connection --device $device --usleep 1000 --staging $staging --occupancy $occupancy --clock $clock --decode"
#nano_readout_options="--connection $connection --device $device --usleep 1000 --staging $staging --occupancy $occupancy --clock $clock --decode --output $outputdir/raw/alcdaq"
nano_readout_options="--connection $connection --device $device --usleep 100 --staging $staging --occupancy $occupancy --clock $clock --output $outputdir/raw/alcdaq"
trig_readout_options="$nano_readout_options --trigger"
echo " --- ctrl-readout options: $ctrl_readout_options " | tee -a $outputdir/log/start-readout-processes.log
echo " --- nano-readout options: $nano_readout_options " | tee -a $outputdir/log/start-readout-processes.log

### start ctrl-readout process
/au/readout/bin/ctrl-readout $ctrl_readout_options &> $outputdir/log/ctrl-readout.log &
echo " --- started ctrl-readout process " | tee -a $outputdir/log/start-readout-processes.log
#sudo -E nice -n -20
#sudo renice -n -20
sleep 1

### start ALCOR nano-readout processes
for chip in {0..5}; do
    enabled=${ENA[$chip]}
    for lane in {0..3}; do
	[[ $(( enabled & (1 << lane) )) = 0 ]] && continue
 	ififo=$(( lane + 4 * chip ))
	
	/au/readout/bin/nano-readout $nano_readout_options --chip $chip --lane $lane &> $outputdir/log/nano-readout.chip$chip.lane$lane.log &

       #sudo -E nice -n -20 
#	sudo renice -n -20

	#	/au/readout/bin/decoder --input $outputdir/raw/alcdaq.fifo_$ififo.dat --output $outputdir/decoded/alcdaq.fifo_$ififo.root &> $outputdir/log/decoder.chip$chip.lane$lane.log && \
#	    root -b -q -l "/home/eic/alcor/alcor-utils/measure/2023-characterisation/ureadout_dcr_analysis.C(\"$outputdir/decoded/alcdaq.fifo_$ififo.root\", \"$outputdir/dcr/alcdaq.fifo_$ififo.dcr.root\")" &> $outputdir/log/ureadout_dcr_analysis.chip$chip.lane$lane.log & 
	
#	    root -b -q -l "/home/eic/alcor/alcor-utils/measure/fastMiniFrame.C(\"$outputdir/decoded/alcdaq.fifo_$ififo.root\", \"$outputdir/miniframe/alcdaq.fifo_$ififo.miniframe.root\")" &> $outputdir/log/fastMiniFrame.chip$chip.lane$lane.log &
	echo " --- started nano-readout process: chip $chip, lane $lane " | tee -a $outputdir/log/start-readout-processes.log
    done
done

### start TRIGGER nano-readout process
if [ $trigg = 1 ]; then
    /au/readout/bin/nano-readout $nano_readout_options --trigger --chip -1 --lane -1 &> $outputdir/log/nano-readout.trigger.log & 
    echo " --- started nano-readout process: trigger " | tee -a $outputdir/log/start-readout-processes.log
fi


### wait for readout processes to complete
echo " --- waiting for readout processes to complete " | tee -a $outputdir/log/start-readout-processes.log
wait

### start ALCOR decoder processes
for chip in {0..5}; do
    enabled=${ENA[$chip]}
    for lane in {0..3}; do
	[[ $(( enabled & (1 << lane) )) = 0 ]] && continue
 	ififo=$(( lane + 4 * chip ))
	
	### not too many at the same time
	while [ $(pgrep -c -f /au/readout/bin/decoder) -gt 16 ]; do sleep 1; done

	/au/readout/bin/decoder --input $outputdir/raw/alcdaq.fifo_$ififo.dat --output $outputdir/decoded/alcdaq.fifo_$ififo.root &> $outputdir/log/decoder.chip$chip.lane$lane.log && if [[ -v DRICH_READOUT_DELETE_RAW ]]; then rm -f $outputdir/raw/alcdaq.fifo_$ififo.dat; fi && root -b -q -l "/home/eic/alcor/alcor-utils/measure/2023-characterisation/ureadout_dcr_analysis.C(\"$outputdir/decoded/alcdaq.fifo_$ififo.root\", \"$outputdir/dcr/alcdaq.fifo_$ififo.dcr.root\")" &> $outputdir/log/ureadout_dcr_analysis.chip$chip.lane$lane.log && if [[ -v DRICH_READOUT_DELETE_DECODED ]]; then rm -f $outputdir/decoded/alcdaq.fifo_$ififo.root; fi &  

	
# sudo -E nice -n -20 	
#	sudo renice -n -20 
	
	echo " --- started decoder process: chip $chip, lane $lane " | tee -a $outputdir/log/start-readout-processes.log
    done
done

### wait for decoder processes to complete
echo " --- waiting for decoder processes to complete " | tee -a $outputdir/log/start-readout-processes.log
wait

### start TRIGGER nano-readout process
if [ $trigg = 1 ]; then
    /au/readout/bin/decoder --input $outputdir/raw/alcdaq.fifo_24.dat --output $outputdir/decoded/alcdaq.fifo_24.root &> $outputdir/log/decoder.trigger.log && if [[ -v DRICH_READOUT_DELETE_RAW ]]; then rm -f $outputdir/raw/alcdaq.fifo_24.dat; fi & # & 
    #	root -b -q -l "/home/eic/alcor/alcor-utils/measure/fastMiniFrame.C(\"$outputdir/decoded/alcdaq.fifo_24.root\", \"$outputdir/miniframe/alcdaq.fifo_24.miniframe.root\")" &

    echo " --- started nano-readout process: trigger " | tee -a $outputdir/log/start-readout-processes.log
fi


### done
echo " --- done " | tee -a $outputdir/log/start-readout-processes.log

