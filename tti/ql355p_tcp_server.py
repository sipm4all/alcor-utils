#! /usr/bin/env python3

import socket
import sys
import os
import serial

timedout1 = 0
timedout2 = 0
timedout3 = 0

OP1_old = None
V1_old = None
I1_old = None
V1O_old = None
I1O_old = None

OP2_old = None
V2_old = None
I2_old = None
V2O_old = None
I2O_old = None

OP3_old = None
V3_old = None
I3_old = None
V3O_old = None
I3O_old = None


import requests
url = 'http://localhost:8086/write?db=mydb'
session = requests.Session()

SOCK='/tmp/ql355p_server.socket'
if os.path.exists(SOCK):
  os.remove(SOCK) 

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('10.0.8.22', 9221)

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

def ask(cmd):
    send(cmd)
    return recv()

connect()
print(' --- TCP device opened: 10.0.8.22/9221 ')
  
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
      if True or OP1 != OP1_old or V1 != V1_old or I1 != I1_old or V1O != V1O_old or I1O != I1O_old or timedout1 > 100:
        OP1_old = OP1
        V1_old = V1
        I1_old = I1
        V1O_old = V1O
        I1O_old = I1O
        thedata = 'ql355p_server,source=CH1,name=STAT value=' + OP1 + '\n'
        thedata += 'ql355p_server,source=CH1,name=VSET value=' + V1 + '\n'
        thedata += 'ql355p_server,source=CH1,name=ISET value=' + I1 + '\n'
        thedata += 'ql355p_server,source=CH1,name=VOUT value=' + V1O + '\n'
        thedata += 'ql355p_server,source=CH1,name=IOUT value=' + I1O
        print(thedata)
        try:
          session.post(url, data=thedata.encode())
        except Exception as e:
          print(e)
        timedout1 = 0
      timedout1 += 1
        
      OP2 = ask('OP2?')
      V2 = ask('V2?').split()[1]
      I2 = ask('I2?').split()[1]
      V2O = ask('V2O?')[:-1]
      I2O = ask('I2O?')[:-1]
      if True or OP2 != OP2_old or V2 != V2_old or I2 != I2_old or V2O != V2O_old or I2O != I2O_old or timedout2 > 100:
        OP2_old = OP2
        V2_old = V2
        I2_old = I2
        V2O_old = V2O
        I2O_old = I2O
        thedata = 'ql355p_server,source=CH2,name=STAT value=' + OP2 + '\n'
        thedata += 'ql355p_server,source=CH2,name=VSET value=' + V2 + '\n'
        thedata += 'ql355p_server,source=CH2,name=ISET value=' + I2 + '\n'
        thedata += 'ql355p_server,source=CH2,name=VOUT value=' + V2O + '\n'
        thedata += 'ql355p_server,source=CH2,name=IOUT value=' + I2O
        print(thedata)
        try:
          session.post(url, data=thedata.encode())
        except Exception as e:
          print(e)
        timedout2 = 0
      timedout2 +=1

      OP3 = ask('OP3?')
      V3 = ask('V3?').split()[1]
      V3O = ask('V3O?')[:-1]
      I3O = ask('I3O?')[:-1]
      if True or OP3 != OP3_old or V3 != V3_old or V3O != V3O_old or I3O != I3O_old or timedout3 > 100:
        OP3_old = OP3
        V3_old = V3
        V3O_old = V3O
        I3O_old = I3O
        thedata = 'ql355p_server,source=AUX,name=STAT value=' + OP3 + '\n'
        thedata += 'ql355p_server,source=AUX,name=VSET value=' + V3 + '\n'
        thedata += 'ql355p_server,source=AUX,name=VOUT value=' + V3O + '\n'
        thedata += 'ql355p_server,source=AUX,name=IOUT value=' + I3O
        print(thedata)
        try:
          session.post(url, data=thedata.encode())
        except Exception as e:
          print(e)
        timedout3 = 0
      timedout3 += 1
      
close()
