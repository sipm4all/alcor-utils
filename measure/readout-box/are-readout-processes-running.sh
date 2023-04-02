#! /usr/bin/env bash

(ps -ef | grep "start-readout-processes.sh" | grep -v grep ) &> /dev/null && echo "YES" && exit 0
(ps -ef | grep "readout/bin/ctrl-readout" | grep -v grep ) &> /dev/null && echo "YES" && exit 0
(ps -ef | grep "readout/bin/nano-readout" | grep -v grep ) &> /dev/null && echo "YES" && exit 0
(ps -ef | grep "readout/bin/decoder" | grep -v grep ) &> /dev/null && echo "YES" && exit 0

echo "NO"
