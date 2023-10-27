#! /usr/bin/env bash

nohup /au/pdu/measure/run-dcr-setup.sh run-testpdu-setup 192 standard "0xf 0xf 0x0 0x0 0x0 0x0" &> run-dcr-setup.log < /dev/null &
