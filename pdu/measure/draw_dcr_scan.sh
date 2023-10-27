#! /usr/bin/env bash

root -b -q -l "${ALCOR_DIR}/pdu/measure/drawing_routines/draw_dcr_scan.C(\".\", $1, $2, $3)"
cp cthr0.png cthr.png
cp cbias5.png cbias.png

### send telegram picture
telegram_picture.sh cthr.png "$PWD"
