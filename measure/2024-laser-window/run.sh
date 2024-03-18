#! /usr/bin/env bash

frequency="1000"
ROWS="A"
COLS="1 2 3 4"
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
    echo " --- make sure we start at room temperature "
    /au/memmert/memmert_back_to_plus_20.sh &> memmert_back_to_plus_20.initial.log
    
    ### initialise moving stages
    
    ### go to minus 30 C
    echo " --- go to minus 30 C "
    /au/memmert/memmert_go_to_minus_30.sh &> memmert_go_to_minus_30.log	
    
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

    ### reference baseline calibration
    echo " --- running reference baseline calibration "
    /au/measure/2024-laser-window/run-baseline-calibration.reference.sh &> run-baseline-calibration.reference.log

    ### reference measurements
    echo " --- start reference measurements "
    measure reference A1

    ### target baseline calibration
    echo " --- running target baseline calibration "
    /au/measure/2024-laser-window/run-baseline-calibration.target.sh &> run-baseline-calibration.target.log

    ### target measurements
    echo " --- start target measurements "    
    for ROW in ${ROWS}; do
	for COL in ${COLS}; do
	    measure target ${ROW}${COL}
	done
    done
    
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
    echo " --- go back to room temperature "
    /au/memmert/memmert_back_to_plus_20.sh &> memmert_back_to_plus_20.initial.log

    ### tarball and delete raw data
    tar zcvf subruns.tgz subruns &> subruns.tarball.log && rm -rf subruns
    
    ### completed
    echo " --- completed "
    telegram_message.sh " completed LASER WINDOW run
 from: $PWD 
  run: ${RUNNAME} "

    ### clean token
    rm -rf /tmp/2024-laser-window-setup.running

}

measure() {
    
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
    
    ### measure with laser off
    /au/measure/2024-laser-window/run-laser-scan.sh ${what} ${channel} database.${what}.${channel}.txt "empty" &> run-laser-scan.${what}.${channel}.empty.log

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
    /au/measure/2024-laser-window/run-laser-scan.sh ${what} ${channel} database.${what}.${channel}.txt "center" &> run-laser-scan.${what}.${channel}.center.reference.log
    
    ### measure top-left
    dx="-0.75"
    dy="-0.75"
    x=$(python -c "print ${center_x} + ${dx}")
    y=$(python -c "print ${center_y} + ${dy}")
    /au/phymotion/move_to.sh ${x} ${y}
    /au/measure/2024-laser-window/run-laser-scan.sh ${what} ${channel} database.${what}.${channel}.txt "top-left" &> run-laser-scan.${what}.${channel}.top-left.reference.log
    
    ### measure top-right
    dx="0.75"
    dy="-0.75"
    x=$(python -c "print ${center_x} + ${dx}")
    y=$(python -c "print ${center_y} + ${dy}")
    /au/phymotion/move_to.sh ${x} ${y}
    /au/measure/2024-laser-window/run-laser-scan.sh ${what} ${channel} database.${what}.${channel}.txt "top-right" &> run-laser-scan.${what}.${channel}.top-right.reference.log
    
    ### measure bottom-left
    dx="-0.75"
    dy="0.75"
    x=$(python -c "print ${center_x} + ${dx}")
    y=$(python -c "print ${center_y} + ${dy}")
    /au/phymotion/move_to.sh ${x} ${y}
    /au/measure/2024-laser-window/run-laser-scan.sh ${what} ${channel} database.${what}.${channel}.txt "bottom-left" &> run-laser-scan.${what}.${channel}.bottom-left.reference.log
    
    ### measure bottom-right
    dx="0.75"
    dy="0.75"
    x=$(python -c "print ${center_x} + ${dx}")
    y=$(python -c "print ${center_y} + ${dy}")
    /au/phymotion/move_to.sh ${x} ${y}
    /au/measure/2024-laser-window/run-laser-scan.sh ${what} ${channel} database.${what}.${channel}.txt "bottom-right" &> run-laser-scan.${what}.${channel}.bottom-right.reference.log

    ### process database and QA
    /au/measure/2024-laser-window/process.sh database.${what}.${channel}.txt &> process.${what}.${channel}.log

}

main
    
