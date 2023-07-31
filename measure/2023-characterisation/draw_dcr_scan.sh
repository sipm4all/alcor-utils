#! /usr/bin/env bash

root -b -q -l "${ALCOR_DIR}/measure/2023-characterisation/drawing_routines/draw_dcr_scan.C(\".\", $1, $2, $3)"
cp cthr0.png cthr.png
cp cbias5.png cbias.png

### send email

attachments="cthr.png cbias.png"
#recipients="roberto.preghenella@bo.infn.it nicola.rubini@bo.infn.it"
#recipients="roberto.preghenella@bo.infn.it pietro.antonioli@bo.infn.it"
recipients="roberto.preghenella@bo.infn.it luigipio.rignanese@bo.infn.it nicola.rubini@bo.infn.it"
mail -r eicdesk01@bo.infn.it \
     -s "[DCR scan] $(basename "`pwd`")" \
     $(for i in $recipients; do echo "$i,"; done) \
     $(for i in $attachments; do echo "-A $i"; done) <<EOF
Working from $PWD.

(Do not reply, we won't read it)
EOF


