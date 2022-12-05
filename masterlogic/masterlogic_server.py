#! /usr/bin/env python3

### python -m serial.tools.miniterm /dev/ttyUSB0 2400 --eol CRLF -e --raw

import socket
import serial
import argparse
import os

import requests
url = 'http://localhost:8086/write?db=mydb'
session = requests.Session()
#headers = {'Content-type': 'application/json', 'Accept': 'text/plain'}

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

ser = serial.Serial(DEV, 115200, timeout=1)
print(' --- serial connection opened:', DEV)

def masterlogic_send(command):
  command = command + '\n'
  ser.write(command.encode())
  data = bytearray()
  while True:
    datum = ser.read()
    if datum == CRAP:
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
            data = masterlogic_send(command)
            print('--- sending data:', data)
            conn.sendall(data.encode())
      except Exception as e:
        print(e)
        pass
      
      temperature = masterlogic_send('L')
      temperature = temperature.split()[2]
      if True or abs(float(temperature) - float(old_temperature)) > 0.05 or timedout > 100:
        thedata = 'masterlogic_server,source=ml' + theml + ',name=temperature value=' + temperature
        print(thedata)
        old_temperature = temperature
        session.post(url, data=thedata.encode())
        timedout = 0
      timedout += 1

      dacs = masterlogic_send('R')
      dacs_lines = dacs.split('\r\n')
      print(dacs_lines)

      thedata = ''
      for line in dacs_lines:
        line = line.split()
        dac = line[0]
        ch = line[1]
        val = line[3][:-2]
        if dac == 'DAC12':
          thedata += 'masterlogic_server,source=ml' + theml + ',name=dac12,channel=' + ch + ' value=' + val + '\n'
        if dac == 'DAC8':
          thedata += 'masterlogic_server,source=ml' + theml + ',name=dac8,channel=' + ch + ' value=' + val + '\n'
          
      thedata = thedata[:-1]
      print(thedata)
      session.post(url, data=thedata.encode())

        
        
ser.close()
