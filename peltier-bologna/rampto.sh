#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: $0 [tstart] [tstop]"
    exit 1 
fi

./peltier_pid_control_client.py "on"

istop=$1

istart=$(/au/tti/tsx1820p_get.py --iset | awk {'print $4'})
for i in $(seq $istart -0.1 $istop); do
    /au/tti/tsx1820p_set.py --iset $i
    sleep 1
done
