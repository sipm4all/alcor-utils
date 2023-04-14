#! /usr/bin/env bash

COMMAND="/au/tti/plh250_server.py"
PIDLOCK="/tmp/plh250_server.pid"

### check arduino server is running, otherwise start it
if [ $(ps -ef | grep plh250_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- plh250 server not running: starting it "
    $COMMAND &> /tmp/plh250_server.log &
    echo $! > $PIDLOCK
fi
