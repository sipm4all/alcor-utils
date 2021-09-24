#! /usr/bin/env bash

echo " --- plotting QA on $1 "
root -b -q -l "${ALCOR_DIR}/readout/macros/plotChip.C(\"$1\")" &> /dev/null
