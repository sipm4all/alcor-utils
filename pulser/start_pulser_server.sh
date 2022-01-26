#! /usr/bin/env bash

COMMAND="/home/eic/alcor/alcor-utils/pulser/pulser_server.py"
PIDLOCK="/tmp/pulser_server.pid"

### check pulser server is running, otherwise start it
if [ $(ps -ef | grep pulser_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- pulser server not running: starting it "
    $COMMAND &> /dev/null &
    echo $! > /tmp/pulser_server.pid
fi
