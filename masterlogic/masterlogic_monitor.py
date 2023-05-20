#! /usr/bin/env python3

### python -m serial.tools.miniterm /dev/ttyUSB0 2400 --eol CRLF -e --raw

import socket
import argparse
import time
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


SOCK='/tmp/masterlogic_server.ML' + str(args['ml']) + '.socket'

while True:
  try:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
      s.connect(SOCK)

      s.sendall('L'.encode())
      temperature = s.recv(1024).decode()
      temperature = temperature.split()[-1] ### R+HACK
      if temperature[0] == '+' or (temperature[0] == '-' and temperature[1] == '-'): ### R+HACK
        temperature = temperature[1:]
      temperature = float(temperature)
      temperature = str(temperature)
      
      s.sendall('R'.encode())
      dacs = s.recv(1024).decode()
      dacs_lines = dacs.split('\r\n')
      
      if True or abs(float(temperature) - float(old_temperature)) > 0.05 or timedout > 100:
        thedata = 'masterlogic_server,source=ml' + theml + ',name=temperature value=' + temperature
        print(thedata)
        old_temperature = temperature
        try:
          session.post(url, data=thedata.encode())
        except Exception as e:
          print(e)
          timedout = 0
          timedout += 1

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
          try:
            session.post(url, data=thedata.encode())
          except Exception as e:
            print(e)
  except Exception as e:
    print(e)
    
        
  time.sleep(1)
    
