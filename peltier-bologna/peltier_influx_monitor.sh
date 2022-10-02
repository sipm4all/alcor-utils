#! /usr/bin/env bash

### get the latest log file
latest=$(ls -atr ~/DATA/peltier/*.log | tail -n1)

### read the last line
theline=$(tail -n1 $latest)

when=$(echo $theline | awk {'print $1'})
when=$(date -d @${when:0:10})

data=$(echo $theline | awk {'print "peltier_monitor,source=power_supply,name=VSET value="$2"\npeltier_monitor,source=power_supply,name=VOUT value="$3"\npeltier_monitor,source=power_supply,name=ISET value="$4"\npeltier_monitor,source=power_supply,name=IOUT value="$5"\npeltier_monitor,source=masterlogic1,name=TEMP value="$6"\npeltier_monitor,source=masterlogic2,name=TEMP value="$7"\npeltier_monitor,source=masterlogic3,name=TEMP value="$8"\npeltier_monitor,source=masterlogic4,name=TEMP value="$9"\npeltier_monitor,source=rhtempsensor,name=TEMP value="$10"\npeltier_monitor,source=rhtempsensor,name=RH   value="$11'})

curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$data"


#echo -e "$data"
