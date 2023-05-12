#! /usr/bin/env bash

timeout 30 $@
if [ $? == 124 ]; then
    echo " --- timed out "
fi

