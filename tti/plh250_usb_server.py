#! /usr/bin/env python3

import socket
import sys
import os
import serial

import requests
url = 'http://localhost:8086/write?db=mydb'
session = requests.Session()

SOCK='/tmp/plh250_server.socket'
if os.path.exists(SOCK):
  os.remove(SOCK) 

ser = serial.Serial('/dev/PLH250', 9600, timeout=1)
print(' --- serial device opened: /dev/PLH250 ')

def send(cmd):
    cmd += '\n'
    ser.write(cmd.encode())

def recv():
    data = ser.readline().decode().strip()
    return data

def ask(cmd):
    send(cmd)
    return recv()

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.bind(SOCK)
    s.listen()
    s.settimeout(1)
    
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
            if command[-1:] == '?':
              print('--- ask instrument:', command)
              data = ask(command)
              print('--- received data:', data)
            else:
              print(' --- send instrument:', command)
              data = command
              send(command)
            print('--- sending data:', data)
            conn.sendall(data.encode())
      except Exception as e:
        print(e)
        pass

      OP1 = ask('OP1?')
      V1 = ask('V1?').split()[1]
      I1 = ask('I1?').split()[1]
      V1O = ask('V1O?')[:-1]
      I1O = ask('I1O?')[:-1]
      thedata = 'plh250_server,source=CH1,name=STAT value=' + OP1 + '\n'
      thedata += 'plh250_server,source=CH1,name=VSET value=' + V1 + '\n'
      thedata += 'plh250_server,source=CH1,name=ISET value=' + I1 + '\n'
      thedata += 'plh250_server,source=CH1,name=VOUT value=' + V1O + '\n'
      thedata += 'plh250_server,source=CH1,name=IOUT value=' + I1O
      print(thedata)
      try:
        session.post(url, data=thedata.encode())
      except Exception as e:
        print(e)

ser.close()
