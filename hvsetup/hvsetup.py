#! /usr/bin/env python

import serial
import time
import sys


if (len(sys.argv)) is not 3:
    print('usage: ./hvsetup.py [hvsettings] [device]')
    exit()

with open(sys.argv[1]) as file:
    lines = file.readlines()
    lines = [line.rstrip() for line in lines]

print('setting DAC values from ' + sys.argv[1] + ' on ' + sys.argv[2]);
print(lines)
sure = raw_input('are you sure? (y/n) ')
if sure != 'y':
    exit()

ser = serial.Serial('/dev/ttyUSB0', baudrate=115200, timeout=0.1)
for line in lines:
    data = line + '\n\r'
    ser.write(data)
    time.sleep(0.1)
    output = ser.readline()
    while output != '':
        output = output.strip()
        if output != '' and output != ':>':
            print(output)
        output = ser.readline()

ser.close()
