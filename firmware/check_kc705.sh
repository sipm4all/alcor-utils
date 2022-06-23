#! /usr/bin/env bash

source /tools/Xilinx/Vivado_Lab/2021.2/.settings64-Vivado_Lab.sh
source /home/eic/alcor/alcor-utils/etc/env.sh

FW="new"
TARGET=210203A62F62A
if [ ! -x $KC705_TARGET ]; then
    TARGET=$KC705_TARGET
fi

ping -c1 10.0.8.15 || /home/eic/alcor/alcor-utils/firmware/program.sh $FW $TARGET true &> /tmp/firmware_program.log
