#! /usr/bin/env bash

START=3
NLOOPS=10
TARGET=-15
EPSILON="0.5"

if [ "$#" -ne 4 ]; then
    echo " usage: ./peltier_control.sh [target temperature] [start current SMALL] [BIG0] [BIG1] "
    echo
    echo " possible magic command: ./peltier_control.sh -15 5.55 4.32 3.50 "
    echo
    exit 1
fi

TARGET=$1
current_small=$2
current_big0=$3
current_big1=$4

echo " --- Peltier control: target temperature:  $TARGET C "
echo "                      SMALL start current: $current_small A "
echo "                      BIG-0 start current: $current_big0 A "
echo "                      BIG-1 start current: $current_big1 A "

./set_small.sh $current_small # $START
./set_big0.sh $current_big0 # $START
./set_big1.sh $current_big1 # $START

Tstart=`date +%s`

if [ ! -f peltier_control.dat ]; then
    echo "timestamp/I:T0/F:T1/F:T2/F:T3/F:T4/F:Tsmall/F:Tbig0/F:Tbig1/F" | tee peltier_control.dat
fi

while true; do

    T0_ave=0
    T1_ave=0
    T2_ave=0
    T3_ave=0
    T4_ave=0
    Tsmall_ave=0
    Tbig0_ave=0
    Tbig1_ave=0
    
    nmeas=0
    
    for I in $(seq $NLOOPS); do

        T0=`./lm73.py ML0 | awk {'print $3'}`
        sleep 0.1
        T1=`./lm73.py ML1 | awk {'print $3'}`
        sleep 0.1
        T2=`./lm73.py ML2 | awk {'print $3'}`
        sleep 0.1
        T3=`./lm73.py ML3 | awk {'print $3'}`
        sleep 0.1
        T4=`./lm73.py ML4 | awk {'print $3'}`
        sleep 0.1

        [ -z $T0 ] && continue;
        [ -z $T1 ] && continue;
        [ -z $T2 ] && continue;
        [ -z $T3 ] && continue;
        [ -z $T4 ] && continue;

        nmeas=$(($nmeas + 1))

        Tsmall=$(bc <<< "scale=2; $T0")
        Tbig0=$(bc <<< "scale=2; ($T2 + $T3 ) * 0.5") 
        Tbig1=$(bc <<< "scale=2; ($T1 + $T4 ) * 0.5")

        T0_ave=$(bc <<< "scale=2; $T0_ave + $T0")
        T1_ave=$(bc <<< "scale=2; $T1_ave + $T1")
        T2_ave=$(bc <<< "scale=2; $T2_ave + $T2")
        T3_ave=$(bc <<< "scale=2; $T3_ave + $T3")
        T4_ave=$(bc <<< "scale=2; $T4_ave + $T4")

        Tsmall_ave=$(bc <<< "scale=2; $Tsmall_ave + $Tsmall")
        Tbig0_ave=$(bc <<< "scale=2; $Tbig0_ave + $Tbig0") 
        Tbig1_ave=$(bc <<< "scale=2; $Tbig1_ave + $Tbig1")

    done

    if [ "$nmeas" == "0" ]; then
        continue
    fi

    T0=$(bc <<< "scale=2; $T0_ave / $nmeas")
    T1=$(bc <<< "scale=2; $T1_ave / $nmeas")
    T2=$(bc <<< "scale=2; $T2_ave / $nmeas")
    T3=$(bc <<< "scale=2; $T3_ave / $nmeas")
    T4=$(bc <<< "scale=2; $T4_ave / $nmeas")
    
    Tsmall=$(bc <<< "scale=2; $Tsmall_ave / $nmeas")
    Tbig0=$(bc <<< "scale=2; $Tbig0_ave / $nmeas") 
    Tbig1=$(bc <<< "scale=2; $Tbig1_ave / $nmeas")
    
    Tstamp=`date +%s`
    

    echo "$Tstamp $T0 $T1 $T2 $T3 $T4 $Tsmall $Tbig0 $Tbig1" | tee -a peltier_control.dat

    Tstamp_start=$(($Tstamp - 3600)) 
    Tstamp_stop=$(($Tstamp + 3600)) 
    root -b -q -l "peltier_control.C($Tstamp_start, $Tstamp_stop)"
    
#    delta_Tstamp=$(bc <<< "scale=2; $Tstamp - $Tstart")
#    if (( $(echo "$delta_Tstamp < 300" | bc -l) )); then
#        echo " --- the system is thermalising, let's wait a bit more "
#        continue
#    fi
    
    delta_small=$(bc <<< "scale=2; $Tsmall - $TARGET")
    delta_big0=$(bc <<< "scale=2; $Tbig0 - $TARGET")
    delta_big1=$(bc <<< "scale=2; $Tbig1 - $TARGET")

    if (( $(echo "$delta_small > $EPSILON" | bc -l) )); then
        echo " --- increase the current of SMALL "
        current_small=$(bc <<< "scale=2; $current_small + 0.05")
        ./set_small.sh $current_small
    elif (( $(echo "$delta_small < -$EPSILON" | bc -l) )); then
        echo " --- decrease the current of SMALL "
        current_small=$(bc <<< "scale=2; $current_small - 0.05")
        ./set_small.sh $current_small
    fi
    
    if (( $(echo "$delta_big0 > $EPSILON" | bc -l) )); then
        echo " --- increase the current of BIG0 "
        current_big0=$(bc <<< "scale=2; $current_big0 + 0.05")
        ./set_big0.sh $current_big0
    elif (( $(echo "$delta_big0 < -$EPSILON" | bc -l) )); then
        echo " --- decrease the current of BIG0 "
        current_big0=$(bc <<< "scale=2; $current_big0 - 0.05")
        ./set_big0.sh $current_big0
    fi
    
    if (( $(echo "$delta_big1 > $EPSILON" | bc -l) )); then
        echo " --- increase the current of BIG1 "
        current_big1=$(bc <<< "scale=2; $current_big1 + 0.05")
        ./set_big1.sh $current_big1
    elif (( $(echo "$delta_big1 < -$EPSILON" | bc -l) )); then
        echo " --- decrease the current of BIG1 "
        current_big1=$(bc <<< "scale=2; $current_big1 - 0.05")
        ./set_big1.sh $current_big1
    fi

    echo " --- last settings: current_small = $current_small | Tsmall = $Tsmall " | tee peltier_control.last
    echo " --- last settings: current_big0 = $current_big0 | Tbig0 = $Tbig0 " | tee -a peltier_control.last
    echo " --- last settings: current_big1 = $current_big1 | Tbig1 = $Tbig1 " | tee -a peltier_control.last
    
done
