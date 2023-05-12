#! /usr/bin/env bash

### check if paused
while [ -f /tmp/run-the-setup.pause ]; do
    echo " $0: paused"
    sleep 60
done

### resume from standby
/au/memmert/resume

### make sure fan is AUTO
while ! (/au/memmert/set --fan A); do
    echo " --- failed to set memmert to T = -30 C"
    sleep 1;
done

### wait for RH to reach baseline
/au/memmert/memmert_reached_rh.sh 5.0

### wait for few minutes to make sure that RH is really low
echo " --- wait 10 minutes to make sure RH is really low"
sleep 600

### change temperature to T = -30 C
while ! (/au/memmert/set --temp -30); do
    echo " --- failed to set memmert to T = -30 C"
    sleep 1;
done

### wait until we are stable
/au/memmert/wait --delta 2 --time 1800 --sleep 5                                             

### send email

recipients="roberto.preghenella@bo.infn.it luigipio.rignanese@bo.infn.it"
mail -r eicdesk01@bo.infn.it \
     -s "[MEMMERT] Reached T = -30 C" \
     $(for i in $recipients; do echo "$i,"; done) <<EOF
Working from $PWD.

(Do not reply, we won't read it)
EOF
