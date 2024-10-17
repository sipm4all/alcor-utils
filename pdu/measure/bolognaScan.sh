#! /usr/bin/env bash

if [ -z $1 ] || [ -z $2 ]; then
    echo " usage: $0 [device] [outputDir] [tagName] [finalScan] "
    exit 1
fi
DEVICE=$1

CONN=/etc/drich/drich_ipbus_connections.xml
OUTDIR="${HOME}/DATA/scan/GIULIA/HAMA1_sn2/20220420/minus30c"
TAGNAME="hvzero"
FINAL_SCAN=false

RANGEMIN=2    ### [0]
RANGEMAX=2    ### [3]
OFFSETMIN=6   ### [6]
OFFSETMAX=7   ### [7]
VTHMIN=0      ### [0]
VTHMAX=3      ### [3]

if [ -n "$2" ]; then
    OUTDIR=$2
fi

if [ -n "$3" ]; then
    TAGNAME=$3
fi

if [ -n "$4" ]; then
    FINAL_SCAN=$4
fi

### create output directory
mkdir -p $OUTDIR

### read fifo settings from ${ALCOR_CONF}/readout.conf
### to make make the chip mask
CHIPMASK=0
RDOUT_CONF=/au/pdu/conf/readout.${DEVICE}.conf
while read -r chip lane eccr bcr pcr; do
    if [ $chip != "#" ] && [ $lane != "0x0" ]; then
	echo " --- chip $chip is active"
	CHIPMASK=$(($CHIPMASK + (1 << $chip)))
    fi
done < $RDOUT_CONF

### settings for baseline scan
LANECHANNELS=$(seq 0 7)
RANGES=$(seq $RANGEMIN $RANGEMAX)
#OFFSETS=$(seq $OFFSETMIN $OFFSETMAX)
OFFSETS="5 7"
VTHS=$(seq $VTHMIN $VTHMAX)
MINTIMER=312500 ## 1 ms
MAXTIMER=312500 ## 1 ms
#MAXTIMER=3200000 ## 100 ms
MINCOUNTS=100
SKIP_USER_SETTING=""

### settings for final scan
if [ "$FINAL_SCAN" = true ]; then
    echo " --- final scan settings"
    RANGES=$(seq -1 -1)
    OFFSETS=$(seq -1 -1)
    VTHS=$(seq -1 -1)
    MINTIMER=312500 ## 10 ms

    MAXTIMER=312500  ## 1 ms
    MAXTIMER=312500  ## 1 ms                                                                                          
#    MAXTIMER=9600000  ## 300 ms

    MINCOUNTS=100
    SKIP_USER_SETTINGS="--skip_user_settings"
fi

# compute how many scans to be done
NTOBEDONE=0
NDONE=0
for LANECHANNEL in $LANECHANNELS; do
for RANGE in $RANGES; do
for OFFSET in $OFFSETS; do
for VTH in $VTHS; do
    NTOBEDONE=$(($NTOBEDONE + 1))
done; done; done; done
echo " --- we need to do $NTOBEDONE scans: brace"

# start looping
START=`date +%s`
for LANECHANNEL in $LANECHANNELS; do

    echo " --- doing lane channel $LANECHANNEL"

for RANGE in $RANGES; do
for OFFSET in $OFFSETS; do
for VTH in $VTHS; do

### initialise

echo " --- initialising chips "
/au/pdu/control/alcorInit.sh $DEVICE 0 /tmp true &> /dev/null

### scan

OUTPUT=$OUTDIR/$TAGNAME.scanthr.lanechannel_$LANECHANNEL.vth_$VTH.range_$RANGE.offset_$OFFSET.txt

echo " --- starting threshold scan on lane channel $LANECHANNEL with chipmask $CHIPMASK"
/au/readout/bin/scan_thr --connection ${CONN} --device $DEVICE \
    --chip_mask $CHIPMASK --channel $LANECHANNEL \
    --vth $VTH --range $RANGE --offset1 $OFFSET $SKIP_USER_SETTINGS \
    --usleep 1000 --udelay 1000 --min_counts $MINCOUNTS \
    --min_timer $MINTIMER --max_timer $MAXTIMER \
    --output $OUTPUT &> /dev/null

echo " --- output written to: $OUTPUT "

NDONE=$(($NDONE + 1))
NLEFT=$(($NTOBEDONE - $NDONE))
NOW=`date +%s`
RUNTIME=$(($NOW-$START))
AVERAGE=$(bc -l <<< "scale=2; $RUNTIME / $NDONE")
LEFT=$(bc -l <<< "scale=0; $AVERAGE * $NLEFT")
END=$(bc -l <<< "scale=0; $NOW + $LEFT")
FINISHDATE=`date --date=@$END`

echo " --- did $NDONE scans in $RUNTIME seconds: $AVERAGE seconds/scan "
echo " --- left with $NLEFT scans: expected $LEFT seconds left "
echo " --- expected finish date/time: $FINISHDATE " 

done
done
done
done

echo " --- all done, so long"
date

### settings for final scan
if [ "$FINAL_SCAN" = false ]; then
    /au/readout/scripts/draw_lanechannel.sh $OUTDIR
fi
