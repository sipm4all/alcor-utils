#! /usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "usage: $0 [device] [nspills]"
    exit 1
fi
device=$1
nspill=$2

runname=$(date +%Y%m%d-%H%M%S)
echo ${runname} > /tmp/drich_run_start.runname

/home/eic/bin/telegram_message.sh "requested START of run on devices ${device} for ${nspill} spills: ${runname}"

### program KC705
/home/eic/bin/drich_kc705_program.sh $device
sleep 5

### ALCOR init
#/home/eic/bin/telegram_message.sh "ALCOR chips init ${device}"
for I in {192..207}; do
###    ln -sf /au/pdu/conf/readout.kc705-$I.run.conf /au/pdu/conf/readout.kc705-$I.conf; ###
    echo ln -sf /au/pdu/conf/readout.kc705-$I.current.conf /au/pdu/conf/readout.kc705-$I.conf;
done
/au/pdu/control/init.sh $device
sleep 5

### start readout processes
#telegram_message.sh "start readout processes ${device}"
/home/eic/bin/influx_write.sh "run,name=number message=\"${runname}\""
/home/eic/bin/influx_write.sh "run,name=status value=1"
/au/pdu/measure/start-readout-processes.sh $runname $device $nspill &
sleep 5

sudo renice -100 $(pgrep ctrl-readout)
sudo renice -100 $(pgrep nano-readout)

#/home/eic/bin/telegram_message.sh "send start of run at the next spill"
/au/pdu/measure/interprocess.sh $device "0x3f9 0x3fd"

/home/eic/bin/influx_write.sh "run,name=status value=2"
/home/eic/bin/telegram_message.sh "running"
wait

/home/eic/bin/telegram_message.sh "run completed, so long"
/home/eic/bin/influx_write.sh "run,name=status value=0"
echo " --- run completed "

/home/eic/bin/drich_qa_plots.sh ${runname} &
