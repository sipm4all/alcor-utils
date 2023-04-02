#! /usr/bin/env bash

cat /home/eic/DATA/2022-testbeam/physics/latest/log/nano-readout.trigger.log | grep triggers | awk '{sum+=$5;} END{print sum;}'
