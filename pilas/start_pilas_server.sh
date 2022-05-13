#! /usr/bin/env bash

COMMAND="/au/pilas/pilas_server.py"
PIDLOCK="/tmp/pilas_server.pid"

### check pilas server is running, otherwise start it
if [ $(ps -ef | grep pilas_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- pilas server not running: starting it "
    $COMMAND &> /dev/null &
    echo $! > $PIDLOCK
fi
