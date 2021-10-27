#! /usr/bin/env bash

for $ML_number in 0 1 2 3 4
do
    ./hvsetup.py hvsettings.zero ML$ML_number
done
