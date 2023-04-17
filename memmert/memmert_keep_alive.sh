#! /usr/bin/env bash

#/au/memmert/get --temp &> /dev/null && exit 0
/au/memmert/get --mode &> /tmp/memmert.mode || /au/memmert/reset

themode=$(cat /tmp/memmert.mode)

if [ $(grep "mode" /tmp/memmert.mode | awk {'print $3'}) = "0" ]; then
    echo " --- memmert MANUAL mode detected: forcing REMOTE mode"
    /au/memmert/set --mode 1

    ### send email
    attachments=""
    recipients="roberto.preghenella@bo.infn.it nicola.rubini@bo.infn.it luigipio.rignanese@bo.infn.it"
    mail -r eicdesk01@bo.infn.it \
	 -s "[MEMMERT WARNING]" \
	 $(for i in $recipients; do echo "$i,"; done) \
	 $(for i in $attachments; do echo "-A $i"; done) <<EOF
[WARNING] memmert MANUAL mode detected: $themode
forcing REMOTE mode: please check what is going on.

(Do not reply, we won't read it)
EOF

fi
    

