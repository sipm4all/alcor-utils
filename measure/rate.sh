#! /usr/bin/env bash

temperature_tag="temperature"
integrated="0.1"

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: rate.sh [chip] [xy_channel] [options]"
    exit 1
fi

chip=$1
xy_channel=$2
eo_channel=$(/au/readout/python/mapping.py --xy2eo $xy_channel)
options=${@:3}

while [[ $# -gt 0 ]]; do
    case $1 in
	--tag)
	    tag=$2
	    temperature_tag="temperature_${tag}"
	    shift # past argument
	    shift # past value
	    ;;
	*)
	    shift # past argument
	    ;;
    esac
done

#/au/control/alcorInit.sh 0 /tmp/ true &> .alcorInit.log
/au/measure/alcor_fast_init.sh $chip $eo_channel &> /dev/null # .alcorInit.log
output=$(/au/readout/bin/rate --connection /au/etc/connection2.xml --chip $chip --channel $eo_channel $options)
[ -z "$output" ] && exit
temperature=$(/au/memmert/get --temp | awk '{print $3}')
echo "$output $temperature_tag = $temperature"

