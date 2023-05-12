#! /usr/bin/env bash

COMMAND="/home/eic/alcor/alcor-utils/keithley/keithley_multiplexer_server.py"
PIDLOCK="/tmp/keithley_multiplexer_server.pid"

### check pulser server is running, otherwise start it
if [ $(ps -ef | grep keithley_multiplexer_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- keithley_multiplexer server not running: starting it "
    $COMMAND &> /dev/null &
    echo $! > /tmp/keithley_multiplexer_server.pid
fi
