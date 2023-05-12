#! /usr/bin/env bash

### change temperature to T = 25 C
while ! (/au/memmert/set --temp 25); do
    echo " --- failed to set memmert to T = 25 C"
    sleep 1;
done

### wait until we are stable
/au/memmert/wait --delta 2 --time 60 --sleep 5

### standby
/au/memmert/standby

### send email

recipients="roberto.preghenella@bo.infn.it luigipio.rignanese@bo.infn.it"
mail -r eicdesk01@bo.infn.it \
     -s "[MEMMERT] Back to T = 25 C and Standby" \
     $(for i in $recipients; do echo "$i,"; done) <<EOF
Working from $PWD.

(Do not reply, we won't read it)
EOF
