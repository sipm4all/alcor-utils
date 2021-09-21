#! /usr/bin/env bash

MONITOR=1
TIMEOUT=3600
RUN=$1

### FILTER BITS
### bit-0 --> summary filter [status header (K28.3) + status words + checksum header (K28.4) + CRC are disabled]
### bit-1 --> crc filter     [checksum header (K28.4) + CRC are disabled]
### bit-2 --> null filter    [not used words (K28.6) are disabled]
### bit-3 --> t0 filter      [frame header (K28.0) + frame number are disabled]

FILTER=$((0xf))

OCCUPANCY=0
FIFOS=$((0x1ffffff))
FIFOS=$((0x1ff00f0))
FIFOS=$((0x1ff0000))
FIFOS=$((0x1fff0f0))
MODE=5



TAG="alcdaq"
DATE=`date '+%Y%m%d%H%M%S'`
DIR="/home/eic/DATA/STANDALONE/$DATE"
DIR=$2
OUTPUT=$DIR/$TAG

# save config
echo "FIFO: $FIFOS " > $OUTPUT/readoutConfig.dump
echo "MODE: $MODE "  >> $OUTPUT/readoutConfig.dump

#mkdir -p $DIR

${ALCOR_DIR}/bin/readout --connection ${ALCOR_ETC}/connection2.xml --device kc705 \
    --reset_fifo \
    --standalone \
    --usleep 1 \
    --monitor $MONITOR \
    --occupancy $OCCUPANCY \
    --timeout $TIMEOUT \
    --fifo $FIFOS \
    --mode $MODE \
    --filter $FILTER \
    --run $RUN \
    --output $OUTPUT | \
    tee $DIR/readout.log
