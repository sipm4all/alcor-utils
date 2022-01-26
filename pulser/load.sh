#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: pulser_load.sh [cmdfile]"
    exit 1
fi

cat $1 | while read line; do ./pulser_cmd.py "$line"; done
