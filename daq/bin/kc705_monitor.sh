#! /usr/bin/env bash

monitor_loop() {    
    while true; do	
	while read -r name ip target firmware monitor; do	    
	    [[ $name =~ ^#.* ]] && continue
	    [[ $monitor == 0 ]] && continue
	    
	    if ping -W 0.1 -c 1 $ip &> /dev/null; then
		need_ping_update 1 $name && update_ping 1 $name
#		./kc705_module_monitor.sh $module $ip $output $name $channel
	    else
		need_ping_update 0 $name && update_ping 0 $name
	    fi
      
	done < /etc/drich/drich_kc705.conf
	sleep 1
    done
}

update_ping() {
    pingstat=$1
    module=$2
    echo $pingstat > /tmp/kc705_monitor.$module.ping.last	
    /home/eic/bin/influx_write.sh "kc705,device=$module,name=ping value=${pingstat}"
}

need_ping_update() {
    pingstat=$1
    module=$2

    ### if file does not exist
#    [ ! -f /tmp/kc705_monitor.$module.ping.last ] && echo "file does not exist"
    [ ! -f /tmp/kc705_monitor.$module.ping.last ] && return 0

    ### if last update is too old
    last=$(date -r /tmp/kc705_monitor.$module.ping.last +%s)
    curr=$(date +%s)
    elap=$((curr - last))
#    [ $elap -gt "60" ] && echo "last update is too old"
    [ $elap -gt "60" ] && return 0

    ### if content is different
#    [ $(cat /tmp/kc705_monitor.$module.ping.last) -ne $pingstat ] && echo "content is different"
    [ $(cat /tmp/kc705_monitor.$module.ping.last) -ne $pingstat ] && return 0

    ### no need for update
#    echo "no need for update"
    return 1
}

### monitor loop
monitor_loop
