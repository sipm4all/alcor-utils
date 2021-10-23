#! /usr/bin/env python

import serial
import time
import sys


if (len(sys.argv)) is not 2:
    print('usage: ./dacs.py [device]')
    exit()

ser = serial.Serial(sys.argv[1], baudrate=115200, timeout=0.1)
data = 'R \r'
ser.write(data)
time.sleep(0.1)
output = ser.readline()
while output != '':
    output = output.strip()
    if output != '' and output != ':>':
        print(output)
    output = ser.readline()

ser.close()
