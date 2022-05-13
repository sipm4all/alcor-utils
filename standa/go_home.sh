#! /usr/bin/env bash
#
/au/standa/cmd --axis 1 --cmd home
/au/standa/cmd --axis 2 --cmd home
/au/standa/cmd --axis 1 --cmd wait
/au/standa/cmd --axis 2 --cmd wait
/au/standa/cmd --axis 1 --cmd zero
/au/standa/cmd --axis 2 --cmd zero
#
