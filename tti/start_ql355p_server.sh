#! /usr/bin/env bash

COMMAND="/home/eic/alcor/alcor-utils/tti/ql355p_server.py"
PIDLOCK="/tmp/ql355p_server.pid"

### check arduino server is running, otherwise start it
if [ $(ps -ef | grep ql355p_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- ql355p server not running: starting it "
    $COMMAND &> /tmp/ql355p_server.log &
    echo $! > $PIDLOCK
fi
