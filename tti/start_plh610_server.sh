#! /usr/bin/env bash

COMMAND="/home/eic/alcor/alcor-utils/tti/plh610_server.py"
PIDLOCK="/tmp/plh610_server.pid"

### check arduino server is running, otherwise start it
if [ $(ps -ef | grep plh610_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- plh610 server not running: starting it "
    $COMMAND &> /tmp/plh610_server.log &
    echo $! > $PIDLOCK
fi
