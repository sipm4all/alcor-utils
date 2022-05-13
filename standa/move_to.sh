#! /usr/bin/env bash
#
if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [step_x] [step_y]"
    exit 1
fi
#
/au/standa/cmd --axis 1 --cmd "move $1"
/au/standa/cmd --axis 2 --cmd "move $2"
/au/standa/cmd --axis 1 --cmd "wait"
/au/standa/cmd --axis 2 --cmd "wait"
#
