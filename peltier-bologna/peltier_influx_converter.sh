#! /usr/bin/env bash

while read theline; do
    
    when=$(echo $theline | awk {'print $1'})
    when="${when:0:10}000000000"

    data=$(echo "$theline $when" | awk {'print "peltier_monitor,source=power_supply,name=VSET value="$2, $12"\npeltier_monitor,source=power_supply,name=VOUT value="$3, $12"\npeltier_monitor,source=power_supply,name=ISET value="$4, $12"\npeltier_monitor,source=power_supply,name=IOUT value="$5, $12"\npeltier_monitor,source=masterlogic1,name=TEMP value="$6, $12"\npeltier_monitor,source=masterlogic2,name=TEMP value="$7, $12"\npeltier_monitor,source=masterlogic3,name=TEMP value="$8, $12"\npeltier_monitor,source=masterlogic4,name=TEMP value="$9, $12"\npeltier_monitor,source=rhtempsensor,name=TEMP value="$10, $12"\npeltier_monitor,source=rhtempsensor,name=RH value="$11, $12'})

    curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "${data}"

#    echo "$data"

done < $1
