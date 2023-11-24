#! /usr/bin/env python3

### python -m serial.tools.miniterm /dev/ttyUSB0 2400 --eol CRLF -e --raw

import socket
import serial
import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('--ml', type=int, choices=[0, 1, 2, 3, 4], required=True, help="masterlogic number")
args = vars(parser.parse_args())

timedout = 0
theml = str(args['ml'])
old_temperature = 666

SOCK='/tmp/masterlogic_server.ML' + theml + '.socket'
if os.path.exists(SOCK):
  os.remove(SOCK)    

DEV='/dev/ML' + theml
if not os.path.exists(DEV):
  print(' --- device not found:', DEV);
  exit(1)
  
READY=bytearray(b':>')
CRAP=bytearray(b'\xf8')
CRAP2=bytearray(b'\xfc')

ser = serial.Serial(DEV, 115200, timeout=1)
print(' --- serial connection opened:', DEV)

def masterlogic_send(command):
  command = command + '\n'
  ser.write(command.encode())
  data = bytearray()
  while True:
    datum = ser.read()
    if datum == CRAP or datum == CRAP2:
      continue
    data += datum
    if data[-2:] == READY:
      data = data[:-2].decode().strip()
      break
  return data

### switch off debug mode 
masterlogic_send('B 0')
masterlogic_send('B 0')
masterlogic_send('B 0')
masterlogic_send('L')

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.bind(SOCK)
    s.listen()
    
    while True:
      try:
        conn, addr = s.accept()
        with conn:
          print('Connected by', addr)
          while True:
            data = conn.recv(1024)
            if not data:
              break
            command = data.decode()
            print('--- received command:', command)
            data = masterlogic_send(command)
            print('--- sending data:', data)
            conn.sendall(data.encode())
      except Exception as e:
        print(e)
        pass
        
ser.close()
