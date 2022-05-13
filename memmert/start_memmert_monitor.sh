#! /usr/bin/env bash

CMD="/home/eic/alcor/alcor-utils/memmert/memmert_monitor.py"
LOGDIR="/home/eic/DATA/memmert"
LOGFILE="$(date +%Y%m%d).memmert_monitor.log"
ERRFILE="/tmp/memmert_monitor.err"
PIDLOCK="/tmp/memmert_monitor.pid"

### kill running process based on the stored PID
if [ -f $PIDLOCK ]; then
    PID=$(cat $PIDLOCK)
    kill $PID &> /dev/null
fi

### kill any remaining memmert_monitor process
for I in $(ps -ef | grep memmert_monitor | grep python3); do
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
/home/eic/alcor/alcor-utils/memmert/draw_memmert.sh &> /tmp/draw_memmert.log
