#! /usr/bin/env bash

if [ -z $1 ] || [ -z $2 ]; then
    echo " usage: memmert_cmd.sh [device] [command] "
    exit 1
fi

DEVICE=$1
COMMAND=$2
TMPFILE="/tmp/.memmert_cmd"

### prepare to read
while [ -f $TMPFILE ]; do sleep 0.1; done
(cat $DEVICE > $TMPFILE) &
sleep 0.5

### send command
TMPPID=$!
echo -e "$COMMAND \r\n" > $DEVICE

### read the response
timeout=5
while [ $(stat -c %s $TMPFILE) = "0" ] && [ $timeout != "0" ] ; do
    sleep 0.1;
    timeout=$(($timeout - 1))
done

if [ $(stat -c %s $TMPFILE) != "0" ]; then
    grep -q ERR $TMPFILE && head -n1 $TMPFILE || tail -n1 $TMPFILE 
else
    echo 0
fi
kill $TMPPID
rm -rf $TMPFILE

