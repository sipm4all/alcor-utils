#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: $0 [current]"
    exit 1 
fi

istop=$1

istart=$(/au/tti/tsx1820p_get.py --iset | awk {'print $4'})
for i in $(seq $istart 0.01 $istop); do
    /au/tti/tsx1820p_set.py --iset $i
    sleep 1
done
