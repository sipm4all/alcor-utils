#! /usr/bin/env bash

CMD="/home/eic/alcor/alcor-utils/tti/tsx1820p_monitor.py"
LOGDIR="/home/eic/DATA/tsx1820p"
LOGFILE="$(date +%Y%m%d).tsx1820p_monitor.log"
ERRFILE="/tmp/tsx1820p_monitor.err"
PIDLOCK="/tmp/tsx1820p_monitor.pid"

### kill running process based on the stored PID
if [ -f $PIDLOCK ]; then
    PID=$(cat $PIDLOCK)
    kill $PID &> /dev/null
fi

### kill any remaining memmert_monitor process
for I in $(ps -ef | grep tsx1820p_monitor | grep python3); do
    kill -9 $I
done

### run process in background and store PID
mkdir -p $LOGDIR
$CMD 2> $ERRFILE 1>> $LOGDIR/$LOGFILE &
date
echo " --- process started "
echo $! > $PIDLOCK

### run plotting script
/home/eic/alcor/alcor-utils/tsx1820p/draw_tsx1820p.sh &> /tmp/draw_tsx1820p.log
