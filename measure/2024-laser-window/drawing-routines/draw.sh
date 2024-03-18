#! /usr/bin/env bash

RUNNAME=$(basename ${PWD})    

if [ $# -ne 1 ]; then
    echo " usage: $0 [database] "
    exit 1
fi
database=$1
notes=$2

echo "std::map<std::string, float> datain = {" > data.h
cat ${database} | grep -v "#" | grep -v "empty" | grep -v "center" | while read line; do
    vbias="$(echo $line | awk {'print $5'})"
    dirname="$(echo $line | awk {'print $6'})"
    filename="${dirname}/decoded/signal.root"
    echo "{ \"${filename}\" , ${vbias} } ," >> data.h
done
echo "};" >> data.h

cp ${ALCOR_DIR}/measure/2024-laser-window/drawing-routines/draw.C .
root -b -q -l draw.C

telegram_picture.sh c.png "${RUNNAME} - ${database}"
