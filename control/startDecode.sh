#! /usr/bin/env bash

for I in $1/alcdaq.fifo_*.dat; do
    NAME="$(basename $I .dat)"
    echo " --- started decoding chain for file $1/$NAME.dat"
    ${ALCOR_DIR}/readout/bin/decoder --input $1/$NAME.dat --output $1/$NAME.decoded > /dev/null && \
	root -b -q -l "${ALCOR_DIR}/readout/macros/makeTree.C(\"$1/$NAME.decoded\", \"$1/$NAME.root\")" > /dev/null && \
	root -b -q -l "${ALCOR_DIR}/readout/macros/makeMiniFrame.C(\"$1/$NAME.root\", \"$1/$NAME.miniframe.root\")" > /dev/null & # && \
#	rm -rf $1/$NAME.decoded $1/$NAME.root &
done

echo " --- waiting for jobs to finish"
wait

echo " --- merging miniframe trees"
hadd -f $1/alcdaq.miniframe.root $1/alcdaq.fifo_*.miniframe.root > /dev/null && rm -rf $1/alcdaq.fifo_*.miniframe.root

echo " --- do, so long and thanks for all the fish"
