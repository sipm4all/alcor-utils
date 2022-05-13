#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [chip] [channel]"
    exit 1
fi
chip=$1
channel="$2"
eochannel=$(/au/readout/python/mapping.py --xy2eo $channel)

if [ ! -z "$AU_DRYRUN" ]; then
    exit
fi

### send .root and .png files via email

attachments=$(ls rate/*/*.root rate/*/*.png)
#recipients="roberto.preghenella@bo.infn.it nicola.rubini@bo.infn.it"
recipients="roberto.preghenella@bo.infn.it"
mail -r eicdesk01@bo.infn.it \
     -s "[Completed] $(basename "`pwd`")" \
     $(for i in $recipients; do echo "$i,"; done) \
     $(for i in $attachments; do echo "-A $i"; done) <<EOF
Working from $PWD.
Completed to scan sensor.

(Do not reply, we won't read it)
EOF

exit

