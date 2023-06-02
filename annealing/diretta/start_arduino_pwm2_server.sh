#! /usr/bin/env bash

COMMAND="/au/annealing/diretta/arduino_pwm2_server.py"
PIDLOCK="/tmp/arduino_pwm2_server.pid"

### check arduino server is running, otherwise start it
if [ $(ps -ef | grep arduino_pwm2_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- arduino PWM2 server not running: starting it "
    $COMMAND &> /tmp/arduino_pwm2_server.log &
    echo $! > $PIDLOCK
fi
