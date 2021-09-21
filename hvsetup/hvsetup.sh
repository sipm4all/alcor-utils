#! /usr/bin/env bash

stty speed 115200 -F $1
echo " --- setting HV on $1 from $2"
read -p " are you sure? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	cat $2 | while read line; do
		echo $line
		(echo -e $line > $1);
		sleep 1; 
	done
fi
