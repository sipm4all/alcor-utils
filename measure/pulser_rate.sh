#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: pulser_rate.sh [chip] [xy_channel] [options]"
    exit 1
fi

chip=$1
xy_channel=$2
eo_channel=$(/au/readout/python/mapping.py --xy2eo $xy_channel)

sleep=0.0

threshold_settings="--delta_threshold 3"
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

### build options
[ -x ${integrated} ] && integrated="0.1"
min_timer=$(bc -l <<< "scale=0; (32000000 * $integrated) / 1")
options="--min_timer ${min_timer} ${threshold_settings}"

### R+HACK
if [ -f ".rhack" ]; then
    /au/pulser/off
    output_off=$(/au/measure/rate.sh $chip $xy_channel $options --tag off)
    /au/measure/ureadout.sh $chip $xy_channel pulser_off &> .pulser_off.log
    echo $output_off >> .pulser_off.log

    /au/pulser/on
    output_on=$(/au/measure/rate.sh $chip $xy_channel $options --tag on)
    /au/measure/ureadout.sh $chip $xy_channel pulser_on &> .pulser_on.log
    echo $output_on >> .pulser_on.log

    rm .rhack
    exit
fi

/au/pulser/off
sleep $sleep
output_off=$(/au/measure/rate.sh $chip $xy_channel $options --tag off)
[ -z "$output_off" ] && exit

/au/pulser/on
sleep $sleep
output_on=$(/au/measure/rate.sh $chip $xy_channel $options --tag on)
[ -z "$output_on" ] && exit

echo "$output_off $output_on"


