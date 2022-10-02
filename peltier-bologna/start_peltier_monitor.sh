#! /usr/bin/env bash

CMD="/home/eic/alcor/alcor-utils/peltier-bologna/peltier_monitor.py"
LOGDIR="/home/eic/DATA/peltier"
LOGFILE="$(date +%Y%m%d).peltier_monitor.log"
ERRFILE="/tmp/peltier_monitor.err"
PIDLOCK="/tmp/peltier_monitor.pid"

### kill running process based on the stored PID
if [ -f $PIDLOCK ]; then
    PID=$(cat $PIDLOCK)
    kill $PID &> /dev/null
fi

### kill any remaining peltier_monitor process
#for I in $(ps -ef | grep peltier_monitor | grep python3); do
#kill -9 $I
#done

### run process in background and store PID
mkdir -p $LOGDIR
$CMD 2> $ERRFILE 1>> $LOGDIR/$LOGFILE &
date
echo " --- process started "
echo $! > $PIDLOCK

### run plotting script
#/home/eic/alcor/alcor-utils/peltier-bologna/draw_peltier.sh &> /tmp/draw_peltier.log
