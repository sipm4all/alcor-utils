#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [dir] [delta]"
    exit 1
fi

dir=$1
delta=$2

for chip in {0..5}; do
    for range in {0..3}; do
	./updatePCR.sh /au/conf/pcr/dcr-setup/$dir/PCR/chip$chip.range$range.pcr $delta > /au/conf/pcr/dcr-setup/$dir/PCR/chip$chip.range$range.delta$delta.pcr;
    done
done
