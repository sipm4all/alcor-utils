#! /usr/bin/env bash

stty speed 115200 -F /dev/$1
echo " --- setting HV on $1"
cat hvsettings.zero | while read line; do
	echo $line
	(echo -e $line > /dev/$1);
	sleep 1; 
done

