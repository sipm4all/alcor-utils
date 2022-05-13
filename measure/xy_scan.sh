#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [chip] [channel]"
    exit 1
fi

CHIP=$1
CHANNEL="$2"

/au/standa/home
/au/standa/move $(/au/standa/maps/read_map.sh /au/standa/maps/20220206/standa_map_extra.dat $CHIP $CHANNEL)
/au/standa/zero

TAGNAME="chip${CHIP}-${CHANNEL}"
FILENAMEX="${TAGNAME}.x_scan.dat"
FILENAMEY="${TAGNAME}.y_scan.dat"

POS=$(seq -4000 160 4000)

REPEAT=10

rm -rf $FILENAMEX
for X in $POS; do
    /au/standa/move $X 0

    for i in $(seq 1 $REPEAT); do
	OUTPUT=$(/au/measure/pulser_rate.sh $CHIP $CHANNEL --delta_threshold 5)
	echo "position_x = $X $OUTPUT" | tee -a $FILENAMEX
    done
    
done
/au/measure/tree.sh $FILENAMEX position_x/I counts_on/I counts_off/I period_on/F period_off/F rate_on/F rate_off/F

rm -rf $FILENAMEY
for Y in $POS; do
    /au/standa/move 0 $Y

    for i in $(seq 1 $REPEAT); do
	OUTPUT=$(/au/measure/pulser_rate.sh $CHIP $CHANNEL --delta_threshold 5)
	echo "position_y = $Y $OUTPUT" | tee -a $FILENAMEY
    done
    
done
/au/measure/tree.sh $FILENAMEY position_y/I counts_on/I counts_off/I period_on/F period_off/F rate_on/F rate_off/F
