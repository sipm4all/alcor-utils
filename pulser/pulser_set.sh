#! /usr/bin/env bash

FREQUENCY=100  # [kHz]
WIDTH=5        # [ns]
VOLTAGE=1000   # [mV]
VOLTAGELO=0    # [mV]

help() {
    cat <<EOF
Options:
   --frequency arg            Pulse frequency [kHz]
   --width arg                Pulse width [ns]
   --voltage arg              Pulse voltage [mV]
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
	--frequency)
	    FREQUENCY="$2"
	    shift # past argument
	    shift # past value
	    ;;
	--width)
	    WIDTH="$2"
	    shift # past argument
	    shift # past value
	    ;;
	--voltage)
	    VOLTAGE="$2"
	    shift # past argument
	    shift # past value
	    ;;
	--voltagelo)
	    VOLTAGELO="$2"
	    shift # past argument
	    shift # past value
	    ;;
	--help)
	    help
	    exit 0
	    ;;
	*)
	    echo "unknown option $1"
	    exit 1
	    ;;
    esac
done

### list of commands to setup the pulser
cat <<EOF |
### reset instrument
*RST
### setup trigger pulse signal
SOURCE1:FUNCTION:SHAPE PULSE
SOURCE1:FREQUENCY ${FREQUENCY} kHz
SOURCE1:PULSE:WIDTH 100 ns
SOURCE1:PULSE:HOLD WIDTH
SOURCE1:PULSE:TRANSITION:LEADING 2.5 ns
SOURCE1:PULSE:TRANSITION:TRAILING 2.5 ns
SOURCE1:PULSE:DELAY 0 ns
SOURCE1:VOLTAGE:LOW 0 V
SOURCE1:VOLTAGE:HIGH 5 V
OUTPUT1:POLARITY NORMAL
OUTPUT1:STATE ON
### setup LED pulse
SOURCE2:FUNCTION:SHAPE PULSE
SOURCE2:FREQUENCY ${FREQUENCY} kHz
SOURCE2:PULSE:WIDTH ${WIDTH} ns
SOURCE2:PULSE:HOLD WIDTH
SOURCE2:PULSE:TRANSITION:LEADING 2.5 ns
SOURCE2:PULSE:TRANSITION:TRAILING 2.5 ns
SOURCE2:PULSE:DELAY 0 ns
SOURCE2:VOLTAGE:LOW ${VOLTAGELO} mV
SOURCE2:VOLTAGE:HIGH ${VOLTAGE} mV
OUTPUT2:POLARITY NORMAL
OUTPUT2:STATE ON
### align channels
SOURCE1:PHASE:INITIATE
EOF
while read line; do
    [ -z "$line" ] && continue
    [ "${line:0:1}" == "#" ] && continue
    echo "$line"
    /au/pulser/cmd "$line"
done
/au/pulser/wait
