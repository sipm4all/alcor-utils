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

SOCK='/tmp/tsx1820p_server.socket'

_tsta = 0
_vset = 0
_vout = 0
_iset = 0
_iout = 0

while loop_forever:

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCK)
        
        tsta = time.time()
        ### vset
        s.sendall(b'V1?')
        vset = s.recv(1024).decode()
        vset = vset.split()[1]
        ### vout
        s.sendall(b'V1O?')
        vout = s.recv(1024).decode()
        vout = vout[:-1]
        ### iset
        s.sendall(b'I1?')
        iset = s.recv(1024).decode()
        iset = iset.split()[1]
        ### iout
        s.sendall(b'I1O?')
        iout = s.recv(1024).decode()
        iout = iout[:-1]
        
        if vset != _vset or vout != _vout or iset != _iset or iout != _iout or (tsta - _tsta) > 10:
            _tsta = tsta
            _vset = vset
            _vout = vout
            _iset = iset
            _iout = iout
            print(tsta, vset, vout, iset, iout)
            sys.stdout.flush()
            
    time.sleep(1)
