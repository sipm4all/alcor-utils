#! /usr/bin/env bash

COMMAND="/home/eic/alcor/alcor-utils/keythley/keythley_multiplexer_server.py"
PIDLOCK="/tmp/keythley_multiplexer_server.pid"

### check pulser server is running, otherwise start it
if [ $(ps -ef | grep keythley_multiplexer_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- keythley_multiplexer server not running: starting it "
    $COMMAND &> /dev/null &
    echo $! > /tmp/keythley_multiplexer_server.pid
fi
