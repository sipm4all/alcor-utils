#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: $0 [output prefix]"
    exit 1
fi

staging=$(( 10 * 1024 * 1024 ))
occupancy=1024

### ALCOR active lanes
chip0=$(( 0x0 ))
chip1=$(( 0x0 ))
chip2=$(( 0x0 ))
chip3=$(( 0x0 ))
chip4=$(( 0xf ))
chip5=$(( 0xf ))

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

### output prefix
output=$1

main() {

    ### build fifo bit map
    fifo=$(( (chip0 << 0) + (chip1 << 4) + (chip2 << 8) + (chip3 << 12)  + (chip4 << 16)  + (chip5 << 20) ))

    ### start ctrl-readout process
    /au/readout/bin/ctrl-readout --connection /au/etc/connection.ch.8.xml \
				 --reset \
				 --usleep 1000 \
				 --fifo $fifo \
				 --filter $filter &> \
				 ctrl-readout.log & sleep 1
    echo " --- started ctrl-readout process "
    
    ### start ALCOR nano-readout processes
    for chip in {0..5}; do
	for lane in {0..3}; do	
       	    bit=$(( 1 << ( lane + 4 * chip ) ))
	    if [ $(( bit & fifo )) = 0 ]; then continue; fi
	    /au/readout/bin/nano-readout --connection /au/etc/connection.ch.8.xml \
					 --usleep 1000 \
					 --output $output \
					 --staging $staging \
					 --occupancy $occupancy \
					 --clock $clock \
					 --chip $chip \
					 --lane $lane &> \
					 nano-readout.chip$chip.lane$lane.log &
	    echo " --- started nano-readout process: chip $chip, lane $lane "
	done
    done

    return
    
    ### start TRIGGER nano-readout process
    /au/readout/bin/nano-readout --connection /au/etc/connection.ch.8.xml \
				 --usleep 1000 \
				 --output $output \
				 --staging $staging \
				 --occupancy $occupancy \
				 --clock $clock \
				 --trigger \
				 --chip -1 \
				 --lane -1 &> \
				 nano-readout.trigger.log &
    echo " --- started nano-readout process: trigger "
}

main
