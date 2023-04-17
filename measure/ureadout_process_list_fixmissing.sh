#! /usr/bin/env bash

if [ -x $1 ]; then
    echo "usage: $0 [listname]"
    exit 1
fi

listname=$1
for I in `grep "repeat_1" $listname | awk {'print $3'}`; do
    dir=$(dirname $I); ls $dir/coincidence.root &> /dev/null && continue
    echo "missing $dir"
    hadd -f $dir/coincidence.root $dir/ureadout.repeat_*.*.coincidence.root;
done
