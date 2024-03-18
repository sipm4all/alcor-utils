#! /usr/bin/env bash

declare -A vbias_voltages
vbias_voltages["A"]="50.5 51.0 52.0 53.0 55.0" ### vbreak = 48.0, vover = 2.5, 3.0, 4.0, 5.0, 7.0
vbias_voltages["B"]="50.5 51.0 52.0 53.0 55.0" ### vbreak = 48.0, vover = 2.5, 3.0, 4.0, 5.0, 7.0
vbias_voltages["C"]="39.0 39.5 40.5 41.5 43.5" ### vbreak = 36.5, vover = 2.5, 3.0, 4.0, 5.0, 7.0

declare -A vbias_channel
vbias_channel["A"]="0"
vbias_channel["B"]="1"
vbias_channel["C"]="2"

declare -A vbias_chip
vbias_chip["reference"]="0"
vbias_chip["target"]="1"

alcor_bcrconfigs="config.300.25.12"
alcor_opmodes="1"
alcor_deltathresholds="5"
range=1
nspill=10
repetitions=3
export AU_BOLOGNASCAN_RANGE=$range

if [ "$#" -ne 4 ]; then
    echo " usage: $0 [what] [channel] [database] [notes] "
    exit 1
fi
what=$1
channel=$2
database=$3
notes=$4
eochannel=$(/au/readout/python/mapping.py --xy2eo $channel)
row="${channel:0:1}"
col="${channel:1:1}"

echo " --- started laser scan: ${what} ${channel} ${notes} "

### create database file if it does not exist
if [ ! -f "$database" ]; then
    echo "# channel bcrconfig opmode deltathreshold vbias directory notes" > $database
fi

### loop over ALCOR BCR configs
for bcrconfig in $alcor_bcrconfigs; do
    echo " --- loop over ALCOR BCR configs: $bcrconfig "
    
    ### loop over bias voltages
    for vbias in ${vbias_voltages[$row]}; do
	echo " --- loop over bias voltages: $vbias "

	### setup HV DAC
	echo " --- setup HV DAC channel ${vbias_channel[$row]} "
	dac=$(/au/masterlogic/hvcalib/hvcalib-malaguti.sh hama3 ${vbias} | grep dac | awk {'print $2'})
	/au/masterlogic/set_dac12 ${vbias_chip[$what]} ${vbias_channel[$row]} $dac

	### loop over ALCOR opmodes
	for opmode in $alcor_opmodes; do
	    echo " --- loop over ALCOR opmodes: $opmode "
	    
	    ### loop over ALCOR deltathresholds
	    for deltathreshold in $alcor_deltathresholds; do
		echo " --- loop over ALCOR deltathresholds: $deltathreshold "
	    	
		### modify PCR to enable one channel in current opmode
		echo " --- modify PCR to enable one channel in current opmode "
		pcrfilein="/home/eic/DATA/baselineScan/latest/PCR/chip${vbias_chip[$what]}.range${range}.pcr"
		pcrfileout="/home/eic/DATA/baselineScan/latest/PCR/chip${vbias_chip[$what]}.range${range}.current.pcr"
		/au/readout/python/updatePCR.py --filein $pcrfilein --opmode $opmode --delta_threshold $deltathreshold --one_channel $eochannel > $pcrfileout
		
		### loop over repetitions
		for repeat in $(seq 1 $repetitions); do
		    echo " --- loop over repetitions: $repeat "
		
		    ### start readout processes
		    echo " --- start readout processes "
		    /au/measure/2024-laser-window/start-readout-processes.${what}.sh ${nspill} &> start-readout-processes.log
		    echo ${channel} ${bcrconfig} ${opmode} ${deltathreshold} ${vbias} $(readlink -e /home/eic/DATA/2024-laser-window/actual/latest/subruns/latest) ${notes} >> $database
		    echo " --- readout done "
		    sleep 1
		
		done
		
	    done
	    ### end of loop over ALCOR deltathresholds
	    echo " --- end of loop over ALCOR deltathresholds "
	    
	done
	### end of loop over ALCOR opmodes
	echo " --- end of loop over ALCOR opmodes "
	
    done
    ### end of loop over bias voltages
    echo " --- end of loop over bias voltages "
    
    ### switch off HV
    echo " --- switch off HV "
    /au/masterlogic/zero ${vbias_chip[$what]} 

done
### end of loop over ALCOR BCR configs
echo " --- end of loop over ALCOR BCR configs "
echo " --- laser scan completed "

