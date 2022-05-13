#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ] || [ -x $3 ]; then
    echo "usage: $0 [chip] [xy_channel] [output]"
    exit 1
fi

chip=$1
xy_channel=$2
output=$3
eo_channel=$(/au/readout/python/mapping.py --xy2eo $xy_channel)

filename="${output}.chip_${chip}.channel_${eo_channel}"

[ -f makeTree.C ]    || cp /au/measure/makeTree.C .
[ -f fastMiniFrame.C ] || cp /au/measure/fastMiniFrame.C .
#[ -f myMiniFrame.C ] || cp /au/measure/myMiniFrame.C .
[ -f coincidence.C ] || cp /au/measure/pulser_coincidence.C coincidence.C

rm ${filename}*.log
for fifo in alcor trigger; do
    what="${filename}.${fifo}"
    echo " --- decoder: $what " && \
	time -p (/au/readout/bin/decoder --input $what.dat --output $what.decoded >> $what.log) && \
	ls -l $what.dat && \
	echo " --- makeTree: $what " && \
	time -p (root -b -q -l "makeTree.C(\"$what.decoded\", \"$what.root\")" >> $what.log) && \
	ls -l $what.decoded && \
	rm $what.decoded && \
	echo " --- fastMiniFrame: $what " && \
	time -p (root -b -q -l "fastMiniFrame.C(\"$what.root\", \"$what.miniframe.root\")" >> $what.log) && \
	ls -l $what.root && \
	rm $what.root
done

hadd -f ${filename}.miniframe.root ${filename}.*.miniframe.root && rm -rf ${filename}.*.miniframe.root
root -b -q -l "coincidence.C(\"${filename}.miniframe.root\", ${chip}, ${eo_channel})" && rm -rf ${filename}.miniframe.root

