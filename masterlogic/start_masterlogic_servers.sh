#! /usr/bin/env bash

for I in {0..3}; do
    /au/masterlogic/start_masterlogic_server.sh $I > /tmp/start_masterlogic_server_ml$I.log 2>&1
done

