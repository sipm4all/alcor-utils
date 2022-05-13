#! /usr/bin/env bash

if [ -x $1 ] || [ -x $2 ]; then
    echo "usage: $0 [filename] [string1] [string2] [...] "
    exit 1
fi

### build header
header=""
for I in "${@:2}"; do
#    header+="$I/F:"
    header+="$I:"
done
echo ${header::-1} > $1.tree

### build table
while IFS= read -r linein; do
    lineout=""
    for I in "${@:2}"; do
	filter=${I::-2}
	lineout+="$(echo "$linein" | sed -n -e "s/^.*${filter} = //p" | awk '{print $1}') "
    done
    echo ${lineout::-1} >> $1.tree
done < $1

root -b -q -l "$HOME/alcor/alcor-utils/measure/tree.C(\"$1.tree\")" > /dev/null
