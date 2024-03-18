#! /usr/bin/env python3

import serial
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--device', type=str, required=True, help="Device")
parser.add_argument('--cmd', type=str, required=True, help="Command")
args = vars(parser.parse_args())

STX = '\x02'
ETX = '\x03'
ACK = '\x06'
NAK = '\x16'

'''
R+ and R- to HOME
S to STOP
+nnn relative move of nnn steps
''' 

status = { 0x00000001 : 'Axis busy' ,
           0x00000002 : 'Command invalid' ,
           0x00000004 : 'Axis waits for synchronisation' ,
           0x00000008 : 'Axis initialised' ,
           0x00000010 : 'Axis limit switch +' ,
           0x00000020 : 'Axis limit switch –' ,
           0x00000040 : 'Axis limit switch center' ,
           0x00000080 : 'Axis limit switch software +' ,
           0x00000100 : 'Axis limit switch software –' ,
           0x00000200 : 'Axis power stage is busy' ,
           0x00000400 : 'Axis is in the ramp' ,
           0x00000800 : 'Axis internal error' ,
           0x00001000 : 'Axis limit switch error' ,
           0x00002000 : 'Axis power stage error' ,
           0x00004000 : 'Axis SFI error' ,
           0x00008000 : 'Axis ENDAT error' ,
           0x00010000 : 'Axis is running' ,
           0x00020000 : 'Axis is in recovery time (s. parameter P13 or P16)' ,
           0x00040000 : 'Axis is in stop current delay time (parameter P43)' ,
           0x00080000 : 'Axis is in position' ,
           0x00100000 : 'Axis APS is ready' ,
           0x00200000 : 'Axis is positioning mode' ,
           0x00400000 : 'Axis is in free running mode' ,
           0x00800000 : 'Axis multi F run' ,
           0x01000000 : 'Axis SYNC allowed'
           }


def send(ser, cmd):
    cmd = STX + '0' + cmd + ':XX' + ETX
    ser.write(cmd.encode())

def recv(ser):
    data = bytearray()
    while True:
        datum = ser.read()
        data += datum
        if datum.decode() == ETX:
            break
    if data.decode()[1] == ACK:
        acknak = 'ACK'
    else:
        acknak = 'NAK '
    data = data.decode()[2:-1].split(':')[0]
    print(acknak)
#    data = acknak + ' ' + data.decode()
    return data

def ask(ser, cmd):
    send(ser, cmd)
    return recv(ser)

try:
    ser = serial.Serial(args['device'], 115200, timeout=1)
    cmd = args['cmd']
    if cmd[-1] == '?':
        cmd = cmd[:-1]
        data = ask(ser, cmd)
        print(data)
        if cmd[0:2] == 'SE' and len(cmd) == 5:
            for i in status:
                if int(data) & i:
                    print(status[i])
    else:
        send(ser, cmd)
    ser.close()
except Exception as e:
    print("Error:", e)

