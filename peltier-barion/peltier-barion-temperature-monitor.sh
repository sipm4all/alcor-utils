#! /usr/bin/env bash

while true; do
    echo "$(date +%s) $(/au/peltier-barion/peltier-barion-client.py --peltier $1 --cmd "T" | awk {'print $2'})" 
done

