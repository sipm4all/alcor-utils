#! /usr/bin/env python3

import socket
import sys
import os
import serial

timedout = 0

OP1_old = None
V1_old = None
I1_old = None
V1O_old = None
I1O_old = None

import requests
url = 'http://localhost:8086/write?db=mydb'
session = requests.Session()

SOCK='/tmp/tsx1820p_server.socket'
if os.path.exists(SOCK):
  os.remove(SOCK) 

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('10.0.8.21', 9221)

def connect():
    sock.connect(server_address)

def close():
    sock.close()

def send(cmd):
    cmd += '\n'
    sock.send(cmd.encode())

def recv():
  data = sock.recv(4096)
  data = data.decode()
  while data[-1] != '\n':
    data += sock.recv(4096)
  return data.strip()
#  data = sock.readline().decode().strip()
#  return data

def ask(cmd):
    send(cmd)
    return recv()

connect()
print(' --- TCP device opened: 10.0.8.21/9221 ')
  
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

      OP1 = ask('OP1?')
      V1 = ask('V1?').split()[1]
      I1 = ask('I1?').split()[1]
      V1O = ask('V1O?')[:-1]
      I1O = ask('I1O?')[:-1]
      if OP1 != OP1_old or V1 != V1_old or I1 != I1_old or V1O != V1O_old or I1O != I1O_old or timedout > 100:
        OP1_old = OP1
        V1_old = V1
        I1_old = I1
        V1O_old = V1O
        I1O_old = I1O
        thedata = 'tsx1820p_server,source=CH1,name=STAT value=' + OP1 + '\n'
        thedata += 'tsx1820p_server,source=CH1,name=VSET value=' + V1 + '\n'
        thedata += 'tsx1820p_server,source=CH1,name=ISET value=' + I1 + '\n'
        thedata += 'tsx1820p_server,source=CH1,name=VOUT value=' + V1O + '\n'
        thedata += 'tsx1820p_server,source=CH1,name=IOUT value=' + I1O
        print(thedata)
        session.post(url, data=thedata.encode())
        timedout = 0
      timedout += 1

close()
