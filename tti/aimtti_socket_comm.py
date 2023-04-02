#! /usr/bin/env python3

import socket
import argparse
import os

### client-server communication socket
#SOCK='/tmp/keythley_multiplexer_server.socket'
#if os.path.exists(SOCK):
#  os.remove(SOCK)

### arguments
parser = argparse.ArgumentParser(description='a server', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('--address', type=str, default='10.0.8.21', help='IP address')
parser.add_argument('--port', type=int, default=9221, help='port')
args = parser.parse_args()

### instrument communication socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = (args.address, args.port)

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

connect()
close()
