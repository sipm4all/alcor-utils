#!/bin/sh
#chips="0 1 2 3 4 5"
chips="4 5"
for c in $chips; do
echo "Scanning chip $c" 
for i in {0..31}; do
 chmask=$((1 << $i)) 
# echo $chmask
 echo "Baseline search for channel $i" 
./thresholdLoop.py ../etc/connection2.xml kc705 -s -i -m $chmask -p 1 -c $c --nowait --eccr 0xb81b --pcrfile ../conf/pcr/standard.pcr | grep Baseline
done
done
