#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo " usage: $0 [run-name] "
    exit 1
fi
runname=$1

RUNDIR="/home/eic/DATA/2024-testbeam/actual/physics/${runname}"

echo " --- "
for KC in ${RUNDIR}/kc705-*; do
    for RAW in ${KC}/raw/*.dat; do
	/au/readout/scripts/raw_counters.sh ${RAW}
    done
echo " --- "
done | tee ${RUNDIR}/raw_counters.log
