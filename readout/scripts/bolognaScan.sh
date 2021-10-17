#! /usr/bin/env bash

BCR_DIR=${ALCOR_CONF}/bcr
PCR_DIR=${ALCOR_CONF}/pcr
CONN=${ALCOR_ETC}/connection2.xml
SWITCH="-s -i -m 0x00000000 -p 0 --eccr 0xb81b"
OUTDIR="/home/eic/DATA/Bologna/scan/TIMING/dev"
#TAGNAME="opti"
#TAGNAME="hvzero.minus20c"
#TAGNAME="hvzero.20c.ibsf.ib2.cg"
TAGNAME="vover3"

mkdir -p $OUTDIR

CHIPS="4 5"
FINAL_SCAN=true

### settings for baseline scan
LANECHANNELS=$(seq 0 7)
RANGES=$(seq 0 3)
OFFSETS=$(seq 0 7)
VTHS=$(seq 0 3)
MINTIMER=320000 ## 10 ms
MAXTIMER=320000 ## 10 ms
MINCOUNTS=100
SKIP_USER_SETTING=""

### settings for final scan
if [ "$FINAL_SCAN" = true ]; then
    echo " --- final scan settings"
    RANGES=$(seq -1 -1)
    OFFSETS=$(seq -1 -1)
    VTHS=$(seq -1 -1)
    MINTIMER=320000 ## 10 ms
    MAXTIMER=320000000 ## 1 s
    MINCOUNTS=10000
    SKIP_USER_SETTINGS="--skip_user_settings"
fi

### make the chip mask
CHIPMASK=0
for CHIP in $CHIPS; do
    echo " --- chip $CHIP is active"
    CHIPMASK=$(($CHIPMASK + (1 << $CHIP)))
done

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

for CHIP in $CHIPS; do
    echo " --- initialising chip $CHIP"
    ${ALCOR_DIR}/control/alcorInit.py $CONN kc705 -c $CHIP $SWITCH --bcrfile manual.chip_$CHIP.bcr --pcrfile manual.chip_$CHIP.pcr &> /dev/null & 
done
wait
sleep 0.1

### scan

OUTPUT=$OUTDIR/$TAGNAME.scanthr.lanechannel_$LANECHANNEL.vth_$VTH.range_$RANGE.offset_$OFFSET.txt

echo " --- starting threshold scan on lane channel $LANECHANNEL with chipmask $CHIPMASK"
${ALCOR_DIR}/readout/bin/scan_thr --connection ${CONN} --device kc705 \
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

#root -b -q -l "draw_channel.C(\"$OUTDIR\", \"$TAGNAME\", $CHIP, $CHANNEL, $RANGE)"

done

echo " --- all done, so long"
date
