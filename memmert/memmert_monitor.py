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

HOST = '127.0.0.1'  # The server's hostname or IP address
PORT = 65432        # The port used by the server

_tset = 0
_temp = 0
_relh = 0

while loop_forever:

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT))
        tsta = time.time()
        s.sendall(b'IN_SP_11')
        tset = s.recv(1024).decode()
        s.sendall(b'IN_PV_11')
        temp = s.recv(1024).decode()
        s.sendall(b'IN_PV_13')
        relh = s.recv(1024).decode()
        
        if tset != _tset or temp != _temp or relh != _relh:
            print(tsta, tset, temp, relh)
            sys.stdout.flush()
            
        _tset = tset
        _temp = temp
        _relh = relh

    time.sleep(1)
