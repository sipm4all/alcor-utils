#! /usr/bin/env bash

echo " --- progam kc705 FPGA ---" 

FWREL="pro"
[ -z "$1" ] || FWREL=$1
DIR="${ALCOR_DIR}/firmware"
BIT="${DIR}/${FWREL}.bit"
LTX="${DIR}/${FWREL}.ltx"
[ -f $BIT ] && { echo " using .bit file: $BIT"; } || { echo " cannot find .bit file: $BIT"; exit; }
[ -f $LTX ] && { echo " using .ltx file: $LTX"; } || { echo " cannot find .ltx file: $LTX"; exit; }

cat <<EOF > /tmp/program.tcl
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
current_hw_device [get_hw_devices xc7k325t_0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xctk325t_0] 0]
set_property PROBES.FILE {$LTX} [get_hw_devices xc7k325t_0]
set_property FULL_PROBES.FILE {$LTX} [get_hw_devices xc7k325t_0]
set_property PROGRAM.FILE {$BIT} [get_hw_devices xc7k325t_0]
program_hw_devices [get_hw_devices xc7k325t_0]
refresh_hw_device [get_hw_devices xc7k325t_0]
EOF

read -p " are you sure? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit
fi

vivado_lab -mode batch -source /tmp/program.tcl
rm -rf vivado*.jou vivado*.log /tmp/program.tcl
