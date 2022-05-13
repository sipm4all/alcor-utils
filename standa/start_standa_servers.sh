#! /usr/bin/env bash

for I in 1 2; do
    /home/eic/alcor/alcor-utils/standa/start_standa_server.sh $I > /tmp/start_standa_server_axis$I.log 2>&1
done

