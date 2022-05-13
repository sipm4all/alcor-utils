#! /usr/bin/env bash

### default parameters
time="0.1"
delta_threshold=3

### help
help() {
    cat <<EOF
    Options:
  --help                      Print help messages
  --chip arg                  ALCOR chip
  --channel arg               SiPM carrier channel
  --time arg (=0.1)           Integrated seconds
  --threshold arg (=-1)       ALCOR threshold value
  --delta_threshold arg (=3)  ALCOR threshold delta
  --vth arg (=-1)             ALCOR threshold offset
  --range arg (=-1)           ALCOR threshold range
  --offset1 arg (=-1)         ALCOR baseline offset
EOF
}

### parse arguments
parseargs() {
    
    while [[ $# -gt 0 ]]; do
	case $1 in
	    --chip)
		chip="$2"
		shift # past argument
		shift # past value
		;;
	    --channel)
		channel="$2"
		shift # past argument
		shift # past value
		;;
	    --xychannel)
		xychannel="$2"
		shift # past argument
		shift # past value
		;;
	    --time)
		time="$2"
		shift # past argument
		shift # past value
		;;
	    --help)
		help
		exit 0
		;;
	    --*)
		echo "unknown option $1"
		exit 1
		;;
	    *)
		POSITIONAL_ARGS+=("$1") # save positional arg
		shift # past argument
		;;
	esac
    done

}

### convert xy-channel to ALCOR channel
if [ ! -x $xychannel ]; then
    channel=$(/au/readout/python/mapping.py --xy2eo $channel)
fi

### check required parameters 
if [ -x $chip ] || [ -x $channel ]; then
    help
    exit 1
fi

### define timer
timer=$(echo "scale=0; $time * 32000000) / 1" | bc -l)

xy_channel=$2
eo_channel=$(/au/readout/python/mapping.py --xy2eo $xy_channel)
#
output=$(/au/control/alcorInit.sh 0 /tmp/ true &> /dev/null && /au/readout/bin/rate --connection /au/etc/connection2.xml --chip $chip --channel $channel --min_timer $timer --delta_threshold $delta_threshold)
temperature=$(/au/memmert/get --temp | awk '{print $3}')
echo "$output temperature = $temperature"
#
