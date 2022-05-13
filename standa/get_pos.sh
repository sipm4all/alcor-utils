#! /usr/bin/env bash

standa_x=$(/au/standa/cmd --axis 1 --cmd "gpos")
standa_y=$(/au/standa/cmd --axis 2 --cmd "gpos")
echo $standa_x $standa_y
