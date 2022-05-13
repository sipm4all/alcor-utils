#! /usr/bin/env python3

import socket
import argparse
import os

### client-server communication socket
SOCK='/tmp/keythley_multiplexer_server.socket'
if os.path.exists(SOCK):
  os.remove(SOCK)

### arguments
parser = argparse.ArgumentParser(description='Keithley ivscan program', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('--address', type=str, default='10.0.8.12', help='IP address')
args = parser.parse_args()

### instrument communication socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = (args.address, 5025)

def connect():
    sock.connect(server_address)

def close():
    sock.close()

def send(command):
    command += '\n'
    sock.send(command.encode())

def recv():
    data = sock.recv(4096)
    data = data.decode()
    while data[-1] != '\n':
        data += sock.recv(4096)
    return data.strip()

def ask(cmd):
    send(cmd)
    return recv()

def initialize():
    send('ABORT')
    send('*RST')
    send('STAT:CLE')
    send('SYST:CLE')
    data = ask('*IDN?')
#    send('*IDN?')
#    data = recv()
    print('--- instrument initialised: %s ' % data)

connect()
initialize()

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
                    if command[-1:] == '?':
                        print('--- ask instrument:', command)
                        data = ask(command)
                        print('--- sending data:', data)
                        conn.sendall(data.encode())
                    else:
                        print(' --- send instrument:', command)
                        send(command)
    except Exception as e:
      print(e)
      pass
    
close()
