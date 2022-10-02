#! /usr/bin/env bash

cat <<EOF |
datasheet,board=SENSL,name=resistance value=113.0
datasheet,board=SENSL,name=breakdown_voltage value=24.45
datasheet,board=SENSL,name=breakdown_voltage_reference_temperature value=21.0
datasheet,board=SENSL,name=breakdown_voltage_temperature_dependence value=21.5
datasheet,board=HAMA1,name=resistance value=54.9
datasheet,board=HAMA1,name=breakdown_voltage value=53.
datasheet,board=HAMA1,name=breakdown_voltage_reference_temperature value=25.0
datasheet,board=HAMA1,name=breakdown_voltage_temperature_dependence value=54.
datasheet,board=HAMA2,name=resistance value=73.2
datasheet,board=HAMA2,name=breakdown_voltage value=38.
datasheet,board=HAMA2,name=breakdown_voltage_reference_temperature value=25.0
datasheet,board=HAMA2,name=breakdown_voltage_temperature_dependence value=34.
datasheet,board=FBK,name=resistance value=54.9
datasheet,board=FBK,name=breakdown_voltage value=32.
datasheet,board=FBK,name=breakdown_voltage_reference_temperature value=24.0
datasheet,board=FBK,name=breakdown_voltage_temperature_dependence value=35.
EOF
while read line; do
    echo $line
    curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary "$line"
done





#echo -e "$data"
