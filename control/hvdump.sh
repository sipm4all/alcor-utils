#!/bin/sh
declare mCarrier=( [1]=FBK-2 [2]=HAMA1-2 [3]=FBK-1 [4]=HAMA2-2 [5]=BCOM-T1 [6]=BCOM-T2 )
SSHC="ssh tb@192.168.0.112"

for i in {1..4}; do
echo "HV Settings carrier $i ${mCarrier[$i]}"
$SSHC "./bin/check-hv $i" | grep DAC12
done
