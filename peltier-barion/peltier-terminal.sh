#! /usr/bin/env bash

python -m serial.tools.miniterm /dev/PELTIER$1 9600 --eol CRLF --raw
