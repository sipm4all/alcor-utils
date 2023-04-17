#! /usr/bin/env bash

dir=$1
for I in $(find $dir -name "coincidence.root"); do

    while [ $(ps -ef | grep "root.exe" | grep -v grep | wc -l) -gt 8 ]; do
	sleep 1
    done

    echo " --- $I "
    root -b -q -l "/home/eic/alcor/alcor-utils/measure/count_coincidences.C(\"$I\")" &
    sleep 0.1
    
done
