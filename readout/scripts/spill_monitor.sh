#! /usr/bin/env bash

/au/readout/bin/register --connection /au/etc/connection2.xml --node regfile.mode --write 0x0
/au/readout/bin/register --connection /au/etc/connection2.xml --node regfile.mode --write 0x1
/au/readout/bin/register --connection /au/etc/connection2.xml --node trigger_info.fifo_reset --write 1
/au/readout/bin/register --connection /au/etc/connection2.xml --node regfile.mode --write 0x5

while true; do
#    /au/readout/bin/register --connection /au/etc/connection2.xml --node trigger_info.fifo_occupancy
    hex=$(/au/readout/bin/register --connection /au/etc/connection2.xml --node trigger_info.fifo_occupancy | awk {'print $3'})
    hex=$(($hex & 0xFFFF))
    printf "%d\n" $(($hex))
    sleep 1
done
