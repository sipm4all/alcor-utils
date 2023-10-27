#! /usr/bin/env bash

fwrepo="/home/eic/alcor/alcor-utils/firmware/REPO"

if [ "$#" -ne 2 ]; then
    echo "usage: $0 [target] [firmware]"
    exit 1
fi
target=$1
firmware=$2

bit="${fwrepo}/${firmware}.bit"
[ ! -f $bit ] && { "cannot find .bit file: ${bit}"; exit 1; }
[ -f /tmp/kc705_program.${target}.running ] && exit 1
touch /tmp/kc705_program.${target}.running

cat <<EOF > /tmp/program.${target}.tcl
open_hw_manager
connect_hw_server -allow_non_jtag
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/${target}]
open_hw_target
current_hw_device [get_hw_devices xc7k325t_0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7k325t_0] 0]
set_property PROGRAM.FILE {$bit} [get_hw_devices xc7k325t_0]
program_hw_devices [get_hw_devices xc7k325t_0]
refresh_hw_device [get_hw_devices xc7k325t_0]
disconnect_hw_server
close_hw_manager
EOF

### if we do not have vivado_lab, source the environment
which vivado_lab &> /dev/null || source /home/eic/alcor/tools/Xilinx/Vivado_Lab/2021.2/.settings64-Vivado_Lab.sh

echo "programming target $target"
vivado_lab -mode batch -source /tmp/program.${target}.tcl
rm -rf vivado*.jou vivado*.log /tmp/program.${target}.tcl
rm /tmp/kc705_program.${target}.running
