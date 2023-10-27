#! /usr/bin/env bash

if [ -f /tmp/run-the-setup.running ]; then
    PID=$(cat /tmp/run-the-setup.running | awk {'print $1'})
    kill $(/au/measure/2022-characterisation/status.sh $PID | tail -n +4 | awk {'print $1'} | tr "\n" " ")
fi
