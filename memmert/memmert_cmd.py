#! /usr/bin/env python3

import socket
import sys

HOST = '127.0.0.1'  # The server's hostname or IP address
PORT = 65432        # The port used by the server

if len(sys.argv) < 2:
    print('usage: ./memmert_cmd.py [command]')
    sys.exit(0)

command = sys.argv[1]
print(' --- sending command:', command)

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((HOST, PORT))
    s.sendall(command.encode())
    data = s.recv(1024).decode()
    print(data)
