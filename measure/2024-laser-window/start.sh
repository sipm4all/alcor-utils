#! /usr/bin/env bash

### check token
if [ -f "/tmp/2024-laser-window-setup.running" ]; then
    echo " --- there is already a running 2024-laser-window setup: $(cat /tmp/2024-laser-window-setup.running)"
    exit 1
fi

DATETIME=$(date +%Y%m%d-%H%M%S)

DIRNAME=$HOME/DATA/2024-laser-window/actual/$DATETIME
mkdir -p $DIRNAME
ln -sfn $DIRNAME $HOME/DATA/2024-laser-window/actual/latest
cd $DIRNAME

echo " --- start 2024-laser-window setup: /au/measure/2024-laser-window/run.sh "
echo "     running from: $DIRNAME "
nohup /au/measure/2024-laser-window/run.sh &> run.log < /dev/null &

echo 
echo " --- TAKE NOTE OF THE DATE/TIME "
echo "     $DATETIME "

cd - &> /dev/null
