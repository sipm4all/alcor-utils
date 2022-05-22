#!/usr/bin/env python3

import socket
import time
import sys
import signal

loop_forever = True
def sigterm_handler(_signo, _stack_frame):
    global loop_forever
    loop_forever = False

signal.signal(signal.SIGTERM, sigterm_handler)
signal.signal(signal.SIGINT, sigterm_handler)

HOST = '10.0.8.101'  # The server's hostname or IP address
PORT = 3482          # The port used by the server

_temp = 0
_relh = 0

while loop_forever:

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT))
        tsta = time.time()
        s.sendall(b'Data')
        data = s.recv(1024).decode().split()
        temp = data[0]
        relh = data[1]
        
        if temp != _temp or relh != _relh:
            print(tsta, temp, relh)
            sys.stdout.flush()
            
        _temp = temp
        _relh = relh

    time.sleep(1)
