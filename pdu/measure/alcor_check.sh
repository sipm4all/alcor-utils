#! /usr/bin/env bash

if [ -x $1 ] | [ -x $2 ] | [ -x $3 ]; then
    echo " usage: $0 [ipaddr] [chip] [lane] "
    exit 1
fi
ipaddr=$1
chip=$2
lane=$3

cmd="/au/readout/bin/register --connection /au/pdu/etc/connection.ch.${ipaddr}.xml"

### run OFF
${cmd} --node regfile.mode --write 0x0
### filter ON
${cmd} --node alcor_controller_id${chip} --write 0x0330000f
${cmd} --node alcor_controller_id${chip}
### filter OFF
#/au/readout/bin/register --connection /au/etc/connection.ch.${ipaddr}.xml --node alcor_controller_id${chip} --write 0x03300000
#/au/readout/bin/register --connection /au/etc/connection.ch.${ipaddr}.xml --node alcor_controller_id${chip}
### run ON
${cmd} --node regfile.mode --write 0x1
### reset FIFO
${cmd} --node alcor_readout_id${chip}_lane${lane}.fifo_reset --write 1
### spill ON
${cmd} --node regfile.mode --write 0x3
### sleep very little
sleep 0.001
### spill OFF
${cmd} --node regfile.mode --write 0x1
### run OFF
${cmd} --node regfile.mode --write 0x0

### read FIFO occupancy
nwords=$(${cmd} --node alcor_readout_id${chip}_lane${lane}.fifo_occupancy | awk {'print $3'})
nwords=$(($nwords & 0xFFFF))
echo " --- there are $nwords words in the FIFO --- "


nwords=$(($nwords - 4))

### first two words are spill ON
for I in $(seq 1 2); do
    word=$(${cmd} --node alcor_readout_id${chip}_lane${lane}.fifo_data | awk {'print $3'})
#    echo "   $word (spill ON)"
done

for I in $(seq 1 $nwords); do
    word=$(${cmd} --node alcor_readout_id${chip}_lane${lane}.fifo_data | awk {'print $3'})
    echo "   $word "
    if [ "$word" != "0x5c5c5c5c" ]; then
	echo " unexpected word "
	exit 1
    fi
done

### last two words are spill OFF
for I in $(seq 1 2); do
    word=$(${cmd} --node alcor_readout_id${chip}_lane${lane}.fifo_data | awk {'print $3'})
#    echo "   $word (spill OFF)"
done

exit 0
