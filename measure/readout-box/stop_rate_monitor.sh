#! /usr/bin/env bash

PIDLOCK="/tmp/rate_monitor.pid"
kill -9 $(cat $PIDLOCK)
