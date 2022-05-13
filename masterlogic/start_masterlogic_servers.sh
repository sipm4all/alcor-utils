#! /usr/bin/env bash

for I in {0..4}; do
    /home/eic/alcor/alcor-utils/masterlogic/start_masterlogic_server.sh $I > /tmp/start_masterlogic_server_ml$I.log 2>&1
done

