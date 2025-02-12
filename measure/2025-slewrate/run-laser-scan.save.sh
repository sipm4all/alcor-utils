#! /usr/bin/env bash

declare -A vbias_voltages
vbias_voltages["A"]="55"
vbias_voltages["B"]="55"
vbias_voltages["C"]="41"

declare -A vbias_channel
vbias_channel["A"]="0"
vbias_channel["B"]="1"
vbias_channel["C"]="2"

declare -A vbias_chip
vbias_chip["reference"]="0"
vbias_chip["target"]="1"
vbias_chip["proto"]="1"

alcor_bcrconfigs="config.300.25.12"
alcor_opmodes="4"
alcor_deltathresholds="10"
alcor_deltathresholds2="20"
range=1
nspill=10
repetitions=100
repetitions_delay=180
export AU_BOLOGNASCAN_RANGE=$range

### baseline business
BASELINE="latest"
BASELINE=${AU_BASELINE_RUN} ### need to check it exists, if not use latest

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

echo " --- started slewrate scan: ${what} ${channel} ${notes} "

### create database file if it does not exist
if [ ! -f "$database" ]; then
    echo "#channel chip bcrconfig opmode deltathr deltathr2 vbias subrun notes" > $database
fi

###
### START OF TESTPULSE RUN
###

if [[ ${notes} == "testpulse" ]]; then
    echo " --- START OF TESTPULSE RUN "
    
    ### modify PCR to enable one channel in testpulse mode
    echo " --- modify PCR to enable one channel in testpulse opmode "
    pcrfilein="/home/eic/DATA/baselineScan/${BASELINE}/PCR/chip${vbias_chip[$what]}.range${range}.pcr"
    pcrfileout="/home/eic/DATA/baselineScan/${BASELINE}/PCR/chip${vbias_chip[$what]}.range${range}.current.pcr"
    /au/readout/python/updatePCR.py --filein $pcrfilein --opmode 2 --delta_threshold 63 --delta_threshold2 63 --one_channel $eochannel > $pcrfileout
    
    ### start readout processes
    echo " --- start readout processes "
    /au/measure/2025-slewrate/start-readout-processes.${what}.testpulse.sh ${nspill} &> start-readout-processes.log
    #    echo ${channel} "bcrconfig" 2 63 63 0 $(readlink -e /home/eic/DATA/2025-slewrate/actual/latest/subruns/latest) ${notes} >> $database
    subrun=$(basename $(realpath /home/eic/DATA/2025-slewrate/actual/latest/subruns/latest))
    echo ${channel} "bcrconfig" 2 63 63 0 ${subrun} ${notes} >> $database
    echo " --- readout done "
    sleep 1
    
    echo " --- END OF TESTPULSE RUN "
    exit
fi

###
### END OF TESTPULSE RUN
###

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
	sleep 1
	
	### loop over ALCOR opmodes
	for opmode in $alcor_opmodes; do
	    echo " --- loop over ALCOR opmodes: $opmode "
	    
	    ### loop over ALCOR deltathresholds
	    for deltathreshold in $alcor_deltathresholds; do
		echo " --- loop over ALCOR deltathresholds: $deltathreshold "
	    	
		### loop over ALCOR deltathresholds2
		for deltathreshold2 in $alcor_deltathresholds2; do
		    echo " --- loop over ALCOR deltathresholds2: $deltathreshold2 "
	    	    
		    ### modify PCR to enable one channel in current opmode
		    echo " --- modify PCR to enable one channel in current opmode "
		    pcrfilein="/home/eic/DATA/baselineScan/${BASELINE}/PCR/chip${vbias_chip[$what]}.range${range}.pcr"
		    pcrfileout="/home/eic/DATA/baselineScan/${BASELINE}/PCR/chip${vbias_chip[$what]}.range${range}.current.pcr"
		    /au/readout/python/updatePCR.py --filein $pcrfilein --opmode $opmode --delta_threshold $deltathreshold --delta_threshold2 $deltathreshold2 --one_channel $eochannel > $pcrfileout

		    ### loop over repetitions
		    for irepeat in $(seq 1 $repetitions); do
			echo " --- loop over repetitions: $irepeat "
			
			### start readout processes
			echo " --- start readout processes "
			/au/measure/2025-slewrate/start-readout-processes.${what}.sh ${nspill} &> start-readout-processes.log
#			echo ${channel} ${bcrconfig} ${opmode} ${deltathreshold} ${deltathreshold2} ${vbias} $(readlink -e /home/eic/DATA/2025-slewrate/actual/latest/subruns/latest) ${notes} >> $database
			subrun=$(basename $(realpath /home/eic/DATA/2025-slewrate/actual/latest/subruns/latest))
			echo ${channel} ${bcrconfig} ${opmode} ${deltathreshold} ${deltathreshold2} ${vbias} ${subrun} ${notes} >> $database

			echo " --- readout done "
			sleep 1
			sleep ${repetitions_delay}
		    done

		done
		### end of loop over ALCOR deltathresholds2
		echo " --- end of loop over ALCOR deltathresholds2 "
		
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

