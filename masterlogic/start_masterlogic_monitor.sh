#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: start_masterlogic_monitor.sh [masterlogic]"
    exit
fi
     
SERVER="/home/eic/alcor/alcor-utils/masterlogic/masterlogic_server.py --ml $1"
CMD="/home/eic/alcor/alcor-utils/masterlogic/masterlogic_monitor.py --ml $1"
LOGDIR="/home/eic/DATA/masterlogic"
LOGFILE="$(date +%Y%m%d).masterlogic_monitor_ml$1.log"
ERRFILE="/tmp/masterlogic_monitor_ml$1.err"
PIDLOCK="/tmp/masterlogic_monitor_ml$1.pid"

### check memert server is running, otherwise start it
if [ $(ps -ef | grep "masterlogic_server.py --ml $1" | grep python3 | wc -l ) = "0" ]; then
    echo " --- masterlogic server ML $1 not running: starting it "
    $SERVER &> /dev/null &
    echo $! > /tmp/masterlogic_server_ml$1.pid
fi

### kill running process based on the stored PID
if [ -f $PIDLOCK ]; then
    PID=$(cat $PIDLOCK)
    kill $PID &> /dev/null
fi

### run process in background and store PID
mkdir -p $LOGDIR
$CMD 2> $ERRFILE 1>> $LOGDIR/$LOGFILE &
date
echo " --- process started "
echo $! > $PIDLOCK

### run plotting script
/home/eic/alcor/alcor-utils/masterlogic/draw_masterlogic.sh $1 &> /tmp/draw_masterlogic_ml$1.log
