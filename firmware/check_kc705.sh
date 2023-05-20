#! /usr/bin/env bash

source $HOME/.bashrc

FW="new"
FW="dev"
TARGET=210203A62F62A
TARGET=210203AB8FBFA
TARGET=210203B1C64EA
TARGET=210203B1C64FA ### COSENZA
if [ ! -x $KC705_TARGET ]; then
    TARGET=$KC705_TARGET
fi

ping -c1 10.0.8.15 && exit 0

/au/firmware/program.sh $FW $TARGET true &> /tmp/firmware_program.log
/au/control/alcorInit.sh 666 /tmp &> /dev/null
