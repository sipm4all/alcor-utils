#! /usr/bin/env bash

(ps -ef | grep baseline-calibration | grep -v grep | grep -v is-baseline-calibration-running.sh) &> /dev/null && echo "YES" && exit 0
(ps -ef | grep bolognaScan | grep -v grep) &> /dev/null && echo "YES" && exit 0

echo "NO"
