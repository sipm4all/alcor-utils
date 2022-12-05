#! /usr/bin/env bash

COMMAND="/home/eic/alcor/alcor-utils/readout/scripts/trigger_monitor.sh"
PIDLOCK="/tmp/trigger_monitor.pid"

### check arduino server is running, otherwise start it
if [ $(ps -ef | grep trigger_monitor.sh | grep -v start_trigger_monitor | grep -v grep | wc -l ) = "0" ]; then
    echo " --- trigger_monitor not running: starting it "
    $COMMAND &> /tmp/trigger_monitor.log &
    echo $! > $PIDLOCK
fi
