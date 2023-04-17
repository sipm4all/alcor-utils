#! /usr/bin/env python3

import socket
import argparse

HOST = '127.0.0.1'  # The server's hostname or IP address
PORT = 65432        # The port used by the server

parser = argparse.ArgumentParser()
parser.add_argument('--mode', default=False, action="store_true", help="mode")
parser.add_argument('--temp', default=False, action="store_true", help="temperature (C)")
parser.add_argument('--rh', default=False, action="store_true", help="relative humidity (%%)")
parser.add_argument('--fan', default=False, action="store_true", help="fan speed")
args = vars(parser.parse_args())

if not any(args.values()):
    parser.error('no arguments provided')

try:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(10)
        s.connect((HOST, PORT))
        
        if args['temp']:
            command = 'IN_PV_11'
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- temperature:', data)
            
        if args['mode']:
            command = 'IN_MODE_10'
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- mode:', data)
            
        if args['rh']:
            command = 'IN_PV_13'
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- humidity:', data)
                
        if args['fan']:
            command = 'IN_SP_15'
            s.sendall(command.encode())
            data = s.recv(1024).decode()
            print(' --- fan:', data)
            
except Exception as e:
    print(e)
    exit(1)

exit(0)



