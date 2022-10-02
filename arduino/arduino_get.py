#! /usr/bin/env python3

import socket
import argparse

SOCK='/tmp/arduino_server.socket'

parser = argparse.ArgumentParser()
parser.add_argument('--temp', default=False, action="store_true", help="get temperature (C)")
parser.add_argument('--rh', default=False, action="store_true", help="relative humidity (%)")
args = vars(parser.parse_args())

if not any(args.values()):
    parser.error('no arguments provided')

try:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCK)
        
        for command in args:
            if args[command]:
                s.sendall(command.encode())
                data = s.recv(1024).decode()
                print(' --- %s: %s' % (command, data))
            
            
except Exception as e:
    print(e)
    exit(1)

exit(0)



