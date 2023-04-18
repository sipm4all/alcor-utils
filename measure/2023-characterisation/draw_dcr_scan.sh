#! /usr/bin/env bash

root -b -q -l "${ALCOR_DIR}/measure/2023-characterisation/drawing_routines/draw_dcr_scan.C(\".\", $1, $2, $3)"

### send email

attachments="cmap.png call.png cpro.png cthr0.png cthr1.png cbias3.png cbias5.png"
#recipients="roberto.preghenella@bo.infn.it nicola.rubini@bo.infn.it"
#recipients="roberto.preghenella@bo.infn.it pietro.antonioli@bo.infn.it"
recipients="roberto.preghenella@bo.infn.it"
mail -r eicdesk02@bo.infn.it \
     -s "[DCR scan] $(basename "`pwd`")" \
     $(for i in $recipients; do echo "$i,"; done) \
     $(for i in $attachments; do echo "-A $i"; done) <<EOF
Working from $PWD.

(Do not reply, we won't read it)
EOF


