#! /usr/bin/env bash

COMMAND="/au/arduino/arduino_server.py"
PIDLOCK="/tmp/arduino_server.pid"

### check arduino server is running, otherwise start it
if [ $(ps -ef | grep arduino_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- arduino server not running: starting it "
    $COMMAND &> /tmp/arduino_server.log &
    echo $! > $PIDLOCK
fi
