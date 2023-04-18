#! /usr/bin/env python3

import socket
import sys
import os
import serial
import math

timedout = 0
old_temperature = 666
old_rh = 666

import requests
url = 'http://localhost:8086/write?db=mydb'
session = requests.Session()

SOCK='/tmp/arduino_server.socket'
if os.path.exists(SOCK):
  os.remove(SOCK) 

ser = serial.Serial('/dev/ARDUINO', 115200, timeout=1)
print(' --- serial device opened: /dev/ARDUINO ')

def recv():
    data = ser.readline().decode().strip()
    return data

def read_temp():
  while True:
    data = recv().split()
    if len(data) == 0:
      continue
    if data[0] == 'Temperature=':
      return data[1]

def read_rh():
  while True:
    data = recv().split()
    if len(data) == 0:
      continue
    if data[0] == 'Humidity=':
      return data[1]

def read_dew():
  temp = float(read_temp())
  rh = float(read_rh())
  gamma = math.log(rh / 100.) + 17.67 * temp / (243.5 + temp)
  dew = gamma * 243.5 / (17.67 - gamma)
  return str(dew)
    
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
            if command == 'temp':
              data = read_temp()
            elif command == 'rh':
              data = read_rh();
            elif command == 'dew':
              data = read_dew();
            elif command == 'both':
              data = read_temp() + " " + read_rh();
            else:
              data = 'invalid'
              print('--- sending data:', data)
            conn.sendall(data.encode())
      except Exception as e:
        print(e)
        pass
        
      temperature = read_temp()
      rh = read_rh()

      if temperature != old_temperature or rh != old_rh or timedout > 100:
        old_temperature = temperature
        old_rh = rh
        thedata_temperature = 'arduino_server,source=arduino,name=temperature value=' + temperature
        thedata_rh = 'arduino_server,source=arduino,name=rh value=' + rh
        thedata = thedata_temperature + '\n' + thedata_rh
        print(thedata)
        try:
          session.post(url, data=thedata.encode())
        except Exception as e:
          print(e)
        timedout = 0
      timedout += 1

ser.close()
