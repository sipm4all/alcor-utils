#!/usr/bin/env python3

import socket
import time
import sys
import signal
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--ml', type=int, choices=[0, 1, 2, 3, 4], required=True, help="masterlogic number")
args = vars(parser.parse_args())

SOCK='/tmp/masterlogic_server.ML' + str(args['ml']) + '.socket'

loop_forever = True
def sigterm_handler(_signo, _stack_frame):
    global loop_forever
    loop_forever = False

signal.signal(signal.SIGTERM, sigterm_handler)
signal.signal(signal.SIGINT, sigterm_handler)

_temp = 0

while loop_forever:

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCK)
        tsta = time.time()
        s.sendall(b'L')
        temp = s.recv(1024).decode().split()[2]
        
    if temp != _temp:
        print(tsta, temp)
        sys.stdout.flush()
            
    _temp = temp

    time.sleep(1)
