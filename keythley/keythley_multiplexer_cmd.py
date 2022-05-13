#! /usr/bin/env python3

import socket
import sys

SOCK='/tmp/keythley_multiplexer_server.socket'

if len(sys.argv) < 2:
    print('usage: ./pulser_cmd.py [command]')
    sys.exit(0)
    
command=sys.argv[1]

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.connect(SOCK)
    s.sendall(command.encode())
    if command[-1:] == '?':
        data = s.recv(1024).decode()
        print(data)
