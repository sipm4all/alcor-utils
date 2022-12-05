#! /usr/bin/env python3

import socket
import argparse

SOCK='/tmp/tsx1820p_server.socket'

parser = argparse.ArgumentParser()
parser.add_argument('--vset', default=False, action="store_true", help="set voltage (V)")
parser.add_argument('--iset', default=False, action="store_true", help="set current (A)")
parser.add_argument('--vout', default=False, action="store_true", help="output voltage (V)")
parser.add_argument('--iout', default=False, action="store_true", help="output current (A)")
parser.add_argument('--status', default=False, action="store_true", help="channel status (on/off)")
parser.add_argument('--power', default=False, action="store_true", help="power (W)")
args = vars(parser.parse_args())

commands = { 'vset' : 'V1?' , 'vout' : 'V1O?' , 'iset' : 'I1?' , 'iout' : 'I1O?' , 'status' : 'OP1?' }

if not any(args.values()):
    parser.error('no arguments provided')

try:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCK)
        
        for command in commands:
          if args[command]:
            s.sendall(commands[command].encode())
            data = s.recv(1024).decode()
            print(' --- %s: %s' % (command, data))
            
            
except Exception as e:
    print(e)
    exit(1)

exit(0)



