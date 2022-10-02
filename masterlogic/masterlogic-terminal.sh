#! /usr/bin/env bash

python -m serial.tools.miniterm /dev/ML$1 115200 --eol LF --raw
