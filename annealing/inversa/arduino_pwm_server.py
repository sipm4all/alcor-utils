#! /usr/bin/env python3

import socket
import sys
import serial
import os

SOCK='/tmp/arduino_pwm_server.socket'
if os.path.exists(SOCK):
  os.remove(SOCK) 

READY=bytearray(b'#\r\n')

def arduino_read():
  data = bytearray()
  while True:
    datum = ser.read()
    data += datum
    if data[-3:] == READY:
      data = data[:-3].decode().strip()
      break
  return data

def arduino_send(command):
  command = command + '\n'
  ser.write(command.encode())
  return arduino_read()

ser = serial.Serial('/dev/ARDUINO_PWM', 9600, timeout=1)
print(' --- serial device opened: /dev/ARDUINO_PWM ')
data = arduino_read()
print(data)

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
            print(' --- sending:', command)
            data = arduino_send(command)
            print(data)
      except Exception as e:
        print(e)
        pass
        
ser.close()
