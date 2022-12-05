#! /usr/bin/env bash

COMMAND="/home/eic/alcor/alcor-utils/measure/readout-box/rate_monitor.sh"
PIDLOCK="/tmp/rate_monitor.pid"

### check arduino server is running, otherwise start it
if [ $(ps -ef | grep rate_monitor.sh | grep -v start_rate_monitor | grep -v grep | wc -l ) = "0" ]; then
    echo " --- rate_monitor not running: starting it "
    $COMMAND &> /tmp/rate_monitor.log &
    echo $! > $PIDLOCK
fi
