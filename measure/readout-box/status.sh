#! /usr/bin/env bash

if [ -f /tmp/run-the-setup.running ]; then
    PID=$(cat /tmp/run-the-setup.running | awk {'print $1'})
    echo " --- RUNNING: $PID "
    ps --forest $(ps -e --no-header -o pid,ppid|awk -vp=$PID 'function r(s){print s;s=a[s];while(s){sub(",","",s);t=s;sub(",.*","",t);sub("[0-9]+","",s);r(t)}}{a[$2]=a[$2]","$1}END{r(p)}')
else
    echo " --- NOT RUNNING "
fi
