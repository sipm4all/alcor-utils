#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 [name]"
    exit 1
fi
_name=$1

while read -r name ip target firmware monitor; do
    [[ $name =~ ^#.* ]] && continue
    [[ $_name != "all" ]] && [[ $_name != $name ]] && continue
    echo " --- programming KC705 $name with firmware $firmware "
    if /home/eic/bin/kc705_program.sh $target $firmware &> /tmp/kc705_program.$name.log; then
	/home/eic/bin/influx_write.sh "kc705,device=$name,name=programmed value=1"
	/home/eic/bin/influx_write.sh "kc705,device=$name,name=firmware message=\"$firmware\""
    else
	/home/eic/bin/influx_write.sh "kc705,device=$name,name=programmed value=0"
	/home/eic/bin/influx_write.sh "kc705,device=$name,name=firmware message=\"failed\""
    fi
done < ${AU_KC705_CONFIG}
