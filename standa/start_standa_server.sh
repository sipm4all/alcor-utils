#! /usr/bin/env bash

# exit

if [ -x $1 ]; then
    echo "usage: start_standa_server.sh [axis]"
    exit
fi

COMMAND="/home/eic/alcor/alcor-utils/standa/standa_server.py --axis $1"
PIDLOCK="/tmp/standa_server_axis$1.pid"

### check standa server is running, otherwise start it
if [ $(ps -ef | grep standa_server.py | grep "\-\-axis $1" | grep python3 | wc -l ) = "0" ]; then
    echo " --- standa #$1 server not running: starting it "
    $COMMAND &> /dev/null &
    echo $! > $PIDLOCK
fi
