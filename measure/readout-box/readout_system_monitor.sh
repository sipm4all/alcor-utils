#! /usr/bin/env bash

### DCR scan
if /au/measure/readout-box/status.sh | grep "NOT RUNNING" &> /dev/null; then
    data="readout_system_monitor,system=dcr_scan value=0"
else
    data="readout_system_monitor,system=dcr_scan value=1"
fi
curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null

### readout baseline scan
if /au/measure/readout-box/is-baseline-calibration-running.sh | grep YES &> /dev/null; then
    data="readout_system_monitor,system=baseline_calibration value=1"
else
    data="readout_system_monitor,system=baseline_calibration value=0"
fi
curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null

### readout processes
if /au/measure/readout-box/are-readout-processes-running.sh | grep YES &> /dev/null; then
    data="readout_system_monitor,system=readout_processes value=1"
else
    data="readout_system_monitor,system=readout_processes value=0"
fi
curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null

### FPGA mode
mode=$(/au/readout/bin/register --connection /au/etc/connection2.xml --node regfile.mode | awk {'print $3'})
mode=$(( mode ))
data="readout_system_monitor,system=fpga_mode value=$mode"
curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null

### run status
mode=$(/au/readout/bin/register --connection /au/etc/connection2.xml --node regfile.mode | awk {'print $3'})
runstat=$(( mode & 0x1 ))
if [ $runstat -ne 0 ]; then
        runstat=1
fi
data="readout_system_monitor,system=run_status value=$runstat"
curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null

### spill status
mode=$(/au/readout/bin/register --connection /au/etc/connection2.xml --node regfile.mode | awk {'print $3'})
spillstat=$(( mode & 0x4 ))
if [ $spillstat -ne 0 ]; then
        spillstat=1
fi
data="readout_system_monitor,system=spill_status value=$spillstat"
curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null

lastup=$(date +%s)
#data="readout_system_monitor,system=last_update value=$mode"
#curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data" &> /dev/null
