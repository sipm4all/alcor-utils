#! /usr/bin/env bash

if [ $# -ne 1 ]; then
    echo " usage: $0 [database] "
    exit 1
fi
database=$1

rm -f ${database%.*}.signal.txt

reference="0"
if [[ ${database} == *"reference"* ]]; then
    reference="1"
fi

cat ${database} | grep -v "#" | while read line; do
    channel="$(echo $line | awk {'print $1'})"
    dirname="$(echo $line | awk {'print $6'})"
    while [ "$(ps -ef | grep "root.exe" | grep "signal.C" | grep -v grep | wc -l)" -ge 8 ]; do sleep 1; done
    echo ${dirname}/decoded/signal.root | tee -a ${database%.*}.signal.txt
    root -b -q -l "${ALCOR_DIR}/measure/2024-laser-window/drawing-routines/signal.C(\"${dirname}/decoded\", \"${channel}\", ${reference})" &> /dev/null &
    sleep 0.1
done

while [ "$(ps -ef | grep "root.exe" | grep "signal.C" | grep -v grep | wc -l)" -ge 1 ]; do sleep 1; done
wait

/au/measure/2024-laser-window/drawing-routines/draw.sh ${database}
tar zcvf ${database%.*}.signal.tgz -T ${database%.*}.signal.txt

