#! /usr/bin/env bash

source /tools/Xilinx/Vivado_Lab/2021.2/.settings64-Vivado_Lab.sh
source /home/eic/alcor/alcor-utils/etc/env.sh

FW="new"
ping -c1 10.0.8.15 || /home/eic/alcor/alcor-utils/firmware/program.sh $FW 210203A62F62A true &> /tmp/firmware_program.log
