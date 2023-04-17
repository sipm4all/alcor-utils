#! /usr/bin/env bash

root -b -q -l "/home/eic/alcor/alcor-utils/measure/2022-characterisation/draw_dcr_scan.C(\"rate/vbias_scan\", $1, $2, $3)"

### send email

attachments="cmap.png call.png cpro.png"
recipients="roberto.preghenella@bo.infn.it nicola.rubini@bo.infn.it luigipio.rignanese@bo.infn.it chiara.fraticelli2@studio.unibo.it"
mail -r eicdesk01@bo.infn.it \
     -s "[DCR scan] $(basename "`pwd`")" \
     $(for i in $recipients; do echo "$i,"; done) \
     $(for i in $attachments; do echo "-A $i"; done) <<EOF
Working from $PWD.

(Do not reply, we won't read it)
EOF


