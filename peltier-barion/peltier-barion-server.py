#! /usr/bin/env python3

### python -m serial.tools.miniterm /dev/ttyUSB0 2400 --eol CRLF -e --raw

import socket
import serial
import argparse
import os
import time

parser = argparse.ArgumentParser()
parser.add_argument('--peltier', type=int, choices=[3, 4], required=True, help="peltier number")
args = vars(parser.parse_args())

SOCK='/tmp/peltier-barion-server.PELTIER' + str(args['peltier']) + '.socket'
if os.path.exists(SOCK):
  os.remove(SOCK)    

DEV='/dev/PELTIER' + str(args['peltier'])
if not os.path.exists(DEV):
  print(' --- device not found:', DEV);
  exit(1)
  
ser = serial.Serial(DEV, 9600, timeout=1)
print(' --- serial connection opened:', DEV)

data = bytearray()
while True:
  datum = ser.read()
  if len(datum) == 0:
    break
  data += datum

print(data.decode())

def send(command):
  command = command
  ser.write(command.encode())
  data = bytearray()
  while True:
    datum = ser.read()
    if datum == b'\x00':
      break
    if datum == b'':
      break
    data += datum
  return data.decode().strip()

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.bind(SOCK)
    s.listen()

    try:
        while True:
            conn, addr = s.accept()
            with conn:
                print('Connected by', addr)
                while True:
                    data = conn.recv(1024)
                    if not data:
                        break
                    command = data.decode()
                    print('--- received command:', command)
                    data = send(command)
                    print('--- sending data:', data)
                    conn.sendall(data.encode())
    except Exception as e:
      print(e)
      pass

ser.close()
