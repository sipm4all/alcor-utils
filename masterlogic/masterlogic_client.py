#!/usr/bin/env python3

import socket
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--ml', type=int, choices=[0, 1, 2, 3, 4], required=True, help="masterlogic number")
parser.add_argument('--cmd', type=str, required=True, help="masterlogic command")
args = vars(parser.parse_args())

SOCK='/tmp/masterlogic_server.ML' + str(args['ml']) + '.socket'

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
    s.connect(SOCK)
    s.sendall(args['cmd'].encode())
    data = s.recv(1024).decode()
print(data)
