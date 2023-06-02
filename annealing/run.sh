#! /usr/bin/env bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo " usage: $0 [temperature] [seconds] "
    exit 1
fi
ANNEALING_TEMPERATURE=$1
ANNEALING_SECONDS=$2

echo " --- starting annealing INVERSA: $ANNEALING_TEMPERATURE C, $ANNEALING_SECONDS seconds "
nohup /au/annealing/inversa/run.sh $ANNEALING_TEMPERATURE $ANNEALING_SECONDS &> /dev/null < /dev/null &

echo " --- starting annealing DIRETTA: $ANNEALING_TEMPERATURE C, $ANNEALING_SECONDS seconds "
nohup /au/annealing/diretta/run.sh $ANNEALING_TEMPERATURE $ANNEALING_SECONDS &> /dev/null < /dev/null &

echo " --- waiting for processes to complete "
wait
echo " --- annealing completed "
