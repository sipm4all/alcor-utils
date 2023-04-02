#! /usr/bin/env bash

for board in hama1 fbk hama2 sensl; do    
    until /au/measure/readout-box/status.sh | grep "\-\-\- NOT RUNNING"; do sleep 10; done
    /au/measure/readout-box/start.sh $board
    sleep 10
done
