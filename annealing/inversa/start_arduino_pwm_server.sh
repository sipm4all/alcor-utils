#! /usr/bin/env bash

COMMAND="/au/annealing/inversa/arduino_pwm_server.py"
PIDLOCK="/tmp/arduino_pwm_server.pid"

### check arduino server is running, otherwise start it
if [ $(ps -ef | grep arduino_pwm_server.py | grep python3 | wc -l ) = "0" ]; then
    echo " --- arduino PWM server not running: starting it "
    $COMMAND &> /tmp/arduino_pwm_server.log &
    echo $! > $PIDLOCK
fi
