#! /usr/bin/env bash

frequency="1000"
ROWS="A"
COLS="1 2 3 4"

ROWS="A B C"
COLS="1 2 3 4"

RUN_TESTPULSE="true"
RUN_EMPTY="false"
RUN_CENTER="true"

DX_POSITIONS=$(seq -3.0 0.25 3.0)
DY_POSITIONS=$(seq -0.75 0.75 0.75)

#ROWS="A"
#COLS="1"

RUNNAME=$(basename ${PWD})    

main() {

    ### check token
    if [ -f "/tmp/2024-laser-window-setup.running" ]; then
	echo " --- there is already a running 2024-laser-window setup: $(cat /tmp/2024-laser-window-setup.running)"
	exit 1
    fi
    echo "$$ $PWD" > /tmp/2024-laser-window-setup.running

    ### telegram message
    telegram_message.sh " started LASER WINDOW run
 from: $PWD 
 rows: ${ROWS}
 cols: ${COLS}
  run: ${RUNNAME} "

    ### make sure we start at room temperature
#    echo " --- make sure we start at room temperature "
#    /au/memmert/memmert_back_to_plus_20.sh &> memmert_back_to_plus_20.initial.log
    
    ### initialise moving stages
#    echo " --- initialise moving stages "
#    /au/phymotion/home.sh
#    /au/phymotion/init.sh
    
    ### go to minus 30 C
#    echo " --- go to minus 30 C "
#    /au/memmert/memmert_go_to_minus_30.sh &> memmert_go_to_minus_30.log	

    ### sleep till 21:00
#    rsleep "21:00"
    
    ### program FPGA firmware
    echo " --- program FPGA firmware: dev "
    /au/firmware/program.sh dev $KC705_TARGET true &> program.log
    sleep 5

    ### turn off pulser
    echo " --- turn off pulser "
    /au/pulser/pulser.off &> pulser.log
    /au/pulser/trigger.off &> pulser.log
    sleep 1
    
    ### switch off HV
    echo " --- switch off HV "
    /au/masterlogic/zero 0
    /au/masterlogic/zero 1
    sleep 1
    
    ### setup pulser
    echo " --- setup pulser "
    /au/pulser/pulser_set.sh --frequency $frequency &> pulser.log
    sleep 1

    ###
    ### MEASUREMENTS
    ###

    ### load reference baseline calibration
    echo " --- load reference baseline calibration "
    BASELINE="20240927-201857" ### T = -30 C
    BASELINE="20250112-085010" ### T = 20 C reference
    export AU_BASELINE_RUN=${BASELINE}
    /au/conf/load-baseline.sh ${BASELINE}

    ### reference measurements
    echo " --- start reference measurements "
    measure reference A1
#    measure reference A2

    ### turn off pulser
    echo " --- turn off pulser "
    /au/pulser/pulser.off &> pulser.log
    /au/pulser/trigger.off &> pulser.log
    sleep 1
    
    ### switch off HV
    echo " --- switch off HV "
    /au/masterlogic/zero 0
    /au/masterlogic/zero 1
    sleep 1
    
    ### go back to room temperature
#    echo " --- go back to room temperature "
#    /au/memmert/memmert_back_to_plus_20.sh &> memmert_back_to_plus_20.initial.log

    ### home moving stages
#    echo " --- home moving stages "
#    /au/phymotion/home.sh

    ### tarball and delete raw data
    tar zcvf subruns.tgz subruns &> subruns.tarball.log && rm -rf subruns
#    tar zcvf subruns.tgz subruns &> subruns.tarball.log
    
    ### completed
    echo " --- completed "
    telegram_message.sh " completed LASER WINDOW run
 from: $PWD 
  run: ${RUNNAME} "

    ### clean token
    rm -rf /tmp/2024-laser-window-setup.running

}

measure() {

    ###
    ### do the actual work
    ###
    
    ### program FPGA firmware
#    echo " --- program FPGA firmware: dev "
#    /au/firmware/program.sh dev $KC705_TARGET true &> program.log
#    sleep 5
    
    what=$1
    channel=$2
    echo " --- measure: ${what} ${channel} "
    
    center_x=$(/au/measure/2024-laser-window/get_center_x.sh ${what} ${channel})
    center_y=$(/au/measure/2024-laser-window/get_center_y.sh ${what} ${channel})
    /au/phymotion/move_to.sh ${center_x} ${center_y}

    ### turn off pulser
    echo " --- turn off pulser "
    /au/pulser/pulser.off &> pulser.log
    /au/pulser/trigger.on &> pulser.log
    sleep 1

    ### testpulse run
    [[ ${RUN_TESTPULSE} == "true" ]] && /au/measure/2025-slewrate/run-laser-scan.sh ${what} ${channel} database.${what}.${channel}.txt "testpulse" &> run-laser-scan.${what}.${channel}.testpulse.log
        
    ### empty run with laser off
#    [[ ${RUN_EMPTY} == "true" ]] && /au/measure/2025-slewrate/run-laser-scan.sh ${what} ${channel} database.${what}.${channel}.txt "empty" &> run-laser-scan.${what}.${channel}.empty.log
        
    ### turn on pulser
    echo " --- turn on pulser "
    /au/pulser/pulser.on &> pulser.log
    /au/pulser/trigger.on &> pulser.log
    sleep 1

    ### measure center
    dx="0"
    dy="0"
    x=$(python -c "print ${center_x} + ${dx}")
    y=$(python -c "print ${center_y} + ${dy}")
    /au/phymotion/move_to.sh ${x} ${y}
    [[ ${RUN_CENTER} == "true" ]] && /au/measure/2025-slewrate/run-laser-scan.sh ${what} ${channel} database.${what}.${channel}.txt "center" &> run-laser-scan.${what}.${channel}.center.log

    ### scan positions
#    for dx in ${DX_POSITIONS}; do
#	for dy in ${DY_POSITIONS}; do
#	    x=$(python -c "print ${center_x} + ${dx}")
#	    y=$(python -c "print ${center_y} + ${dy}")
#	    /au/phymotion/move_to.sh ${x} ${y}
#	    /au/measure/2025-slewrate/run-laser-scan.sh ${what} ${channel} database.${what}.${channel}.txt "dx=${dx},dy=${dy}" &> run-laser-scan.${what}.${channel}.dx${dx}.dy${dy}.log
#	done
#    done
    
    ### process database and QA
#    /au/measure/2025-slewrate/process.sh database.${what}.${channel}.txt &> process.${what}.${channel}.log

}

main
    
