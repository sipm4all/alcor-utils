#! /usr/bin/env bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo " usage: $0 [temperature] [seconds] "
    exit 1
fi
ANNEALING_TEMPERATURE=$1
ANNEALING_SECONDS=$2

### tweak temperature a bit
ANNEALING_TEMPERATURE=$(echo "$ANNEALING_TEMPERATURE * (175./171.)" | bc -l)

### make sure arduino PWM server is up and healthy
/au/annealing/diretta/arduino_pwm2_cmd.py --cmd "PWM 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"

### make sure PWMs are all zeros
/au/annealing/diretta/arduino_pwm2_cmd.py --cmd "PWM 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"

### configure power supply and turn on
/au/tti/plh610_cmd.py "V1 10.0"
/au/tti/plh610_cmd.py "I1 1.0"
/au/tti/plh610_cmd.py "OP1 1"

### start PWM annealing server and monitor
nohup /au/annealing/diretta/pwm2_annealing_server.py &> /dev/null < /dev/null &
sleep 10
nohup /au/annealing/diretta/pwm2_annealing_monitor.py &> /dev/null < /dev/null &
sleep 10

### send goto 175 C command
/au/annealing/diretta/pwm2_annealing_client.py "goto ${ANNEALING_TEMPERATURE}"

### sleep for 2 minutes ramp-up time
### and 30 minutes annealing time
sleep 120
sleep ${ANNEALING_SECONDS}

### send goto 40 C command
/au/annealing/diretta/pwm2_annealing_client.py "goto 40"

### sleep for 5 minutes ramp-down time
sleep 300

### quit PWM annealing server and turn off power supply
/au/annealing/diretta/pwm2_annealing_client.py "quit"
/au/tti/plh610_cmd.py "OP1 0"

### make sure PWMs are all zeros
/au/annealing/diretta/arduino_pwm2_cmd.py --cmd "PWM 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
