#! /usr/bin/env bash

### get the latest log file
latest=$(ls -atr ~/DATA/peltier/*.log | tail -n1)

### read the last line
theline=$(tail -n1 $latest)

when=$(echo $theline | awk {'print $1'})
when=$(date -d @${when:0:10})

data=$(echo $theline | awk {'print $2, $3, $4, $5, $6, $7, $8, $9, $10, $11'} | tr " " \\t)

echo "last updated on $when"
echo
echo -e "VSET \t VOUT \t ISET \t IOUT \t TEMP1 \t TEMP2 \t TEMP3 \t TEMP4 \t TIN \t RHIN"
echo -e "$data"
