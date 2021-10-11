#! /usr/bin/env bash

vivado_lab -mode batch -source ${ALCOR_DIR}/firmware/program.tcl
rm -rf vivado*.jou vivado*.log
