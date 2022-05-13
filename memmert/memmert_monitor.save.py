#! /usr/bin/env python

### example to run mini terminal 
### python -m serial.tools.miniterm /dev/ttyUSB0 2400 --eol CRLF -e --raw

import serial
import time
import sys
import os

ser = serial.Serial('/dev/ttyUSB0', 2400, timeout=1)
gotlock = False

def memmert_in(command):
    ser.write(command + '\r\n')
    data = ser.readline().strip()
    if data == 'OK':
        data = ser.readline().strip()
    return data

def memmert_lock():
    global gotlock
    if gotlock:
        return True
    try:
        os.open('/tmp/memmert_lock',  os.O_CREAT | os.O_EXCL)
        gotlock = True
    except: 
        gotlock = False
    return gotlock
    
def memmert_unlock():
    global gotlock
    if gotlock and os.path.exists('/tmp/memmert_lock'):
        os.remove('/tmp/memmert_lock')
    gotlock = False

_tset = 0
_temp = 0
_relh = 0

try:
    while True:

        if True: #memmert_lock():
            tsta = time.time()
            tset = memmert_in('IN_SP_11')
            temp = memmert_in('IN_PV_11')
            relh = memmert_in('IN_PV_13')
            if tset != _tset or temp != _temp or relh != _relh: 
                print tsta, tset, temp, relh
                sys.stdout.flush()
            _tset = tset
            _temp = temp
            _relh = relh
            
#        memmert_unlock()
        time.sleep(1)
        
except:
    pass

#if gotlock:
#    memmert_unlock()
ser.close()
sys.exit(0)
