#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 [name]"
    exit 1
fi
name=$1

/home/eic/bin/alcor-init.sh $name
