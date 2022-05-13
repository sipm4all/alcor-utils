#! /usr/bin/env bash

COMMAND="/home/eic/alcor/alcor-utils/memmert/memmert_server.py"
PIDLOCK="/tmp/memmert_server.pid"

### check memmert server is running, otherwise start it
if [ $(ps -ef | grep memmert_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- memmert server not running: starting it "
    $COMMAND &> /dev/null &
    echo $! > $PIDLOCK
fi

### check communication is healty, otherwise kill, reset and restart
