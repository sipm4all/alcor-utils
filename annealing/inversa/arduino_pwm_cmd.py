#! /usr/bin/env python3

import socket
import argparse

SOCK='/tmp/arduino_pwm_server.socket'

parser = argparse.ArgumentParser()
parser.add_argument('--cmd', type=str, help="send raw command")
args = vars(parser.parse_args())

if not any(args.values()):
    parser.error('no arguments provided')

try:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCK)
        s.sendall(args['cmd'].encode())            
            
except Exception as e:
    print(e)
    exit(1)

exit(0)



