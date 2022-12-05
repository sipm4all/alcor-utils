#! /usr/bin/env bash

COMMAND="/home/eic/alcor/alcor-utils/tti/tsx1820p_server.py"
PIDLOCK="/tmp/tsx1820p_server.pid"

### check arduino server is running, otherwise start it
if [ $(ps -ef | grep tsx1820p_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- tsx1820p server not running: starting it "
    $COMMAND &> /tmp/tsx1820p_server.log &
    echo $! > $PIDLOCK
fi
