#! /usr/bin/env bash

COMMAND="/home/eic/alcor/alcor-utils/peltier-bologna/peltier_pid_control.py"
PIDLOCK="/tmp/peltier_pid_control.pid"

### check arduino server is running, otherwise start it
if [ $(ps -ef | grep peltier_pid_control.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- peltier_pid_control not running: starting it "
    $COMMAND &> /tmp/peltier_pid_control.log &
    echo $! > $PIDLOCK
fi
