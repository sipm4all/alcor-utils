#! /usr/bin/env bash

subject="Test automatic email notification"
message="This is a test email for automatic notifications. Do not reply, we won't read it."

attachments="/home/eic/DATA/memmert/PNG/draw_memmert_2h.png /home/eic/DATA/memmert/PNG/draw_memmert_8h.png /home/eic/DATA/memmert/PNG/draw_memmert_24h.png"
recipients="roberto.preghenella@bo.infn.it nicola.rubini@bo.infn.it giulia.fazzino2@studio.unibo.it"

mail -r eicdesk01@bo.infn.it \
     -s "$subject" \
     $(for i in $recipients; do echo "$i,"; done) \
     $(for i in $attachments; do echo "-A $i"; done) <<EOF
This is a test email for automatic notifications.
Do not reply, we won't read it.
EOF
