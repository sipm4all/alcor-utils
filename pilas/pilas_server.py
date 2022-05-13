#! /usr/bin/env python3

### python -m serial.tools.miniterm /dev/ttyUSB0 2400 --eol CRLF -e --raw

import socket
import serial
import os

SOCK='/tmp/pilas_server.socket'
if os.path.exists(SOCK):
  os.remove(SOCK)    

DEV='/dev/PILAS'
if not os.path.exists(DEV):
  print(' --- device not found:', DEV);
  exit(1)

ser = serial.Serial(port=DEV, baudrate=19200, timeout=0.5)
print(' --- serial connection opened:', DEV)

unsupported_commands = ("version?", "help?")

def pilas_send(command):
  command = command + '\r'
  ser.write(command.encode())
  data = ser.readline().decode().strip()
  return data

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
                    if command in unsupported_commands:
                      data = "unsupported!"
                    else:
                      data = pilas_send(command)
                    print('--- sending data:', data)
                    conn.sendall(data.encode())
    except Exception as e:
      print(e)

ser.close()
