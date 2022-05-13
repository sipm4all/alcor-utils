#! /usr/bin/env bash

timeout 1 $@
if [ $? == 124 ]; then
    echo " --- timed out "
fi

