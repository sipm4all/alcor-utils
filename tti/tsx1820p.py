#! /usr/bin/env python3

import sys
import serial

ser = serial.Serial('/dev/TSX1820P', 9600, timeout=1)

def send(cmd):
    cmd += '\n'
    ser.write(cmd.encode())

def recv():
    data = ser.readline().decode().strip()
    return data

def ask(cmd):
    send(cmd)
    return recv()

if len(sys.argv) < 2:
    print('usage: ./tsx1820p.py [command]')
    sys.exit(0)

command = sys.argv[1]

if command[-1:] == '?':
    print('--- ask instrument:', command)
    data = ask(command)
    print('--- received data:', data)
else:
    print(' --- send instrument:', command)
    send(command)

ser.close()
