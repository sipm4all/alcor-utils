#! /usr/bin/env bash

### check if paused
while [ -f /tmp/run-the-setup.pause ]; do
    echo " $0: paused"
    sleep 60
done

/au/memmert/memmert_reached_rh.sh 5.0

### change temperature to T = -30 C and wait until we are stable
while ! (/au/memmert/set --temp -30); do
    echo " --- failed to set memmert to T = -30 C"
    sleep 1;
done
/au/memmert/wait --delta 2 --time 1800 --sleep 5                                             
