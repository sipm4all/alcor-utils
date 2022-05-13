#!/usr/bin/env python3

import socket
import sys

if len(sys.argv) < 2:
    print('usage: ./pilas_cmd.py [command]')
    sys.exit(0)

SOCK='/tmp/pilas_server.socket'

command = sys.argv[1]
print(' --- sending command:', command)

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.connect(SOCK)
    s.sendall(command.encode())
    data = s.recv(1024).decode()
    print(data)
    
