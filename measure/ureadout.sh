#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ] || [ -x $3 ]; then
    echo "usage: $0 [chip] [xy_channel] [output] [options]"
    exit 1
fi

chip=$1
xy_channel=$2
output=$3
eo_channel=$(/au/readout/python/mapping.py --xy2eo $xy_channel)

integrated="0.1"
threshold_settings="--delta_threshold = 3"
while [[ $# -gt 0 ]]; do
    case $1 in
	--integrated)
	    integrated="$2"
	    shift # past argument
	    shift # past value
	    ;;
 	--threshold)
	    threshold_settings="--threshold $2"
	    shift # past argument
	    shift # past value
	    ;;
 	--delta_threshold)
	    threshold_settings="--delta_threshold $2"
	    shift # past argument
	    shift # past value
	    ;;
	*)
	    shift # past argument
	    ;;
    esac
done
options="--timer 3200000 --integrated ${integrated} ${threshold_settings}"

/au/readout/bin/ureadout --connection /au/etc/connection2.xml --output ${output} --chip ${chip} --channel ${eo_channel} ${options}
#./process.sh "pulser_on.loop_${LOOP}.vbias=${VBIAS}" ${CHIP} ${EOCHANNEL}
