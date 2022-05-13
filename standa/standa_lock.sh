#! /usr/bin/env bash

for axis in 1 2; do
    echo "axis ${axis}: $(/au/standa/cmd --axis ${axis} --cmd "lock")"
done
