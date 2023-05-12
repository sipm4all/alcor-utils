#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: $0 [tag]"
    exit 1
fi

tag=$1
root -b -q -l "/home/eic/alcor/alcor-utils/measure/2023-characterisation/drawing_routines/draw_iv.C(\".\", \"$tag\")"

### send email

attachments="ivmap.png"
#recipients="roberto.preghenella@bo.infn.it nicola.rubini@bo.infn.it"
recipients="roberto.preghenella@bo.infn.it luigipio.rignanese@bo.infn.it"
mail -r eicdesk01@bo.infn.it \
     -s "[IV scan] $(basename "`pwd`")" \
     $(for i in $recipients; do echo "$i,"; done) \
     $(for i in $attachments; do echo "-A $i"; done) <<EOF
Working from $PWD.

(Do not reply, we won't read it)
EOF


