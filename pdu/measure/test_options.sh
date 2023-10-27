#!/bin/bash

LONG=city1:,city2:,help
OPTS=$(getopt -n $0 --options '' --longoptions $LONG -- "$@")
echo $OPTS
