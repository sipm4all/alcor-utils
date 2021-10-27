#! /usr/bin/env bash

_term() { 
  echo "Caught SIGINT signal!" 
  kill -INT "$child" 2>/dev/null
}

trap _term SIGINT

TAG="alcdaq"
RUN=$1
DIR=$2
mkdir -p $DIR

OCCUPANCY=0  # minimum occupancy to download fifo
MODE=5       # run mode [should be 5 to use beam signals]
KILLER=8193  # kill fifo is occupancy is >=

USLEEP=1     # polling sleeps [us]
MONITOR=2   # monitor cycle [s]
TIMEOUT=900  # terminate readout after [s]

### FILTER BITS
### bit-0 --> summary filter [status header (K28.3) + status words + checksum header (K28.4) + CRC are disabled]
### bit-1 --> crc filter     [checksum header (K28.4) + CRC are disabled]
### bit-2 --> null filter    [not used words (K28.6) are disabled]
### bit-3 --> t0 filter      [frame header (K28.0) + frame number are disabled]

FILTER=$((0xf))

### read fifo settings from ${ALCOR_CONF}/readout.conf
RDOUT_CONF=${ALCOR_CONF}/readout.conf
FIFOS=0
while read -r chip lane eccr bcr pcr; do
    if [ $chip != "#" ]; then
	THISFIFO=$(( $lane << (4 * $chip) ))
	FIFOS=$(($FIFOS + $THISFIFO))
    fi
done < $RDOUT_CONF

### read the trigger fifo
FIFOS=$(($FIFOS + 0x1000000))

### save config
echo "FIFOS:     $FIFOS "     | tee    $OUTPUT/readoutConfig.dump
echo "MODE:      $MODE "      | tee -a $OUTPUT/readoutConfig.dump
echo "FILTER:    $FILTER "    | tee -a $OUTPUT/readoutConfig.dump
echo "OCCUPANCY: $OCCUPANCY " | tee -a $OUTPUT/readoutConfig.dump
echo "KILLER:    $KILLER "    | tee -a $OUTPUT/readoutConfig.dump

### start readout
OUTPUT=$DIR/$TAG
${ALCOR_DIR}/readout/bin/readout --connection ${ALCOR_ETC}/connection2.xml --device kc705 \
    --reset_fifo --standalone \
    --usleep $USLEEP --monitor $MONITOR --occupancy $OCCUPANCY --timeout $TIMEOUT \
    --fifo $FIFOS --mode $MODE --filter $FILTER --killer $KILLER \
    --run $RUN --output $OUTPUT \
    | tee $DIR/readout.log &

child=$!
wait "$child"
sleep 2
exit 0
