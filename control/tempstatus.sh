#!/bin/sh

today=`date +%Y-%m-%d`
SSHC="ssh tb@192.168.0.112"
echo "Status Peltier 1"
$SSHC "tail -n 1 /mnt/nfs/spin1/harp/data/Peltier-1_$today.txt"
echo "Status Peltier 2"
$SSHC "tail -n 1 /mnt/nfs/spin1/harp/data/Peltier-2_$today.txt"
