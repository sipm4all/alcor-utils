#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo " usage: $0 [board] [vbias]"
    exit 1
fi
vbias=$2
board=$1
res=""

case $board in

  "hama1")
      res="54.900"
    ;;

  "hama2")
      res="73.200"
    ;;

  "sensl")
      res="113.000"
    ;;

  "fbk")
      res="54.900"
    ;;

  "bcom")
      res="88.700"
    ;;

  *)
      echo "unknown board: " $board
      exit 1
    ;;
esac

### get DAC value
dac=$(python -c "print(int(round(1000. * ${vbias} / ( (1000. / ${res} ) + 1. ))))")

### print output
echo " board: ${board} "
echo " vbias: ${vbias} "
echo "   dac: ${dac} "
