#! /usr/bin/env bash

CMD="/home/eic/alcor/alcor-utils/dht22/dht22_monitor.py"
LOGDIR="/home/eic/DATA/dht22"
LOGFILE="$(date +%Y%m%d).dht22_monitor.log"
ERRFILE="/tmp/dht22_monitor.err"
PIDLOCK="/tmp/dht22_monitor.pid"

### kill running process based on the stored PID
if [ -f $PIDLOCK ]; then
    PID=$(cat $PIDLOCK)
    kill $PID &> /dev/null
fi

### kill any remaining memmert_monitor process
for I in $(ps -ef | grep dht22_monitor | grep python3); do
    kill -9 $I
done

### run process in background and store PID
mkdir -p $LOGDIR
#ln -sf $LOGDIR/$LOGFILE $LOGDIR/current.memmert_monitor.log
$CMD 2> $ERRFILE 1>> $LOGDIR/$LOGFILE &
date
echo " --- process started "
echo $! > $PIDLOCK

### run plotting script
/home/eic/alcor/alcor-utils/dht22/draw_dht22.sh &> /tmp/draw_dht22.log
