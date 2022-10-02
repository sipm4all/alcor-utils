#! /usr/bin/env python3

import socket
import sys

SOCK='/tmp/ql355p_server.socket'

if len(sys.argv) < 2:
    print('usage: ./memmert_cmd.py [command]')
    sys.exit(0)

command = sys.argv[1]

try:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCK)
        s.sendall(command.encode())
        data = s.recv(1024).decode()
        print(' --- %s: %s' % (command, data))

except Exception as e:
    print(e)
