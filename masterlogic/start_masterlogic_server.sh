#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: start_masterlogic_server.sh [masterlogic]"
    exit
fi

COMMAND="/home/eic/alcor/alcor-utils/masterlogic/masterlogic_server.py --ml $1"
PIDLOCK="/tmp/masterlogic_server_ml$1.pid"

### check masterlogic server is running, otherwise start it
if [ $(ps -ef | grep masterlogic_server.py | grep "\-\-ml $1" | grep python3 | wc -l ) = "0" ]; then
    echo " --- masterlogic #$1 server not running: starting it "
    $COMMAND &> /tmp/masterlogic_server_ml$1.log &
    echo $! > $PIDLOCK
fi
