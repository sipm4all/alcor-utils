#! /usr/bin/env bash

maxjobs=8

if [ -x $1 ]; then
    echo "usage: $0 [list]"
    exit 1
fi

filename=$1
#directory=$(dirname $filename)
listname=$filename

#echo "cd $directory"
#cd $directory

cp /au/measure/makeTree.C .
cp /au/measure/myMiniFrame.C .
cp /au/measure/pulser_coincidence.C coincidence.C

while read line; do

    ### make sure we have a free running slot
    while [ $(ls /tmp/*.ureadout_process.running | wc -l) -ge $maxjobs ]; do
	sleep 1
    done
    
    tag=$(echo $line | tr " " "." | tr "/" ".")
    running=/tmp/$tag.ureadout_process.running
    log=/tmp/$tag.ureadout_process.log
    touch $running
    echo "/au/measure/ureadout_process.sh $line --> $running"
    (/au/measure/ureadout_process.sh $line && rm $running) &> $log &
    
done < $listname

wait

#for I in `find ureadout/vbias_scan -name ureadout.repeat_1.*.coincidence.root`; do
for I in `grep "repeat_1" $listname | awk {'print $3'}`; do
    dir=$(dirname $I)
    hadd -f $dir/coincidence.root $dir/ureadout.repeat_*.*.coincidence.root
done
