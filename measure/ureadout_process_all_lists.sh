#! /usr/bin/env bash

if [ -z "$1" ]; then
    echo "usage: $0 [searchdir]"
    exit 1
fi

for I in $(find $1 -name process.list); do
    time -p /au/measure/ureadout_process_list.sh $I;
done
